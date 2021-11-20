---
title: "Anomaly Scoring"
chapter: false
weight: 10
---

> The Core Rule Set 3 is designed as an anomaly scoring rule set. This page explains what anomaly scoring is and how to use it.

## Overview of Anomaly Scoring

Anomaly scoring, also known as "collaborative detection", is a scoring mechanism used in the Core Rule Set. It assigns a numeric score to HTTP transactions (requests and responses), representing how 'anomalous' they appear to be. Anomaly scores can then be used to make blocking decisions. The default CRS blocking policy, for example, is to block any transaction that meets or exceeds a defined anomaly score threshold.

## How Anomaly Scoring Mode Works

Anomaly scoring mode combines the concepts of *collaborative detection* and *delayed blocking*. The key idea to understand is that **the inspection/detection rule logic is decoupled from the blocking functionality**.

Individual rules designed to detect specific types of attacks and malicious behavior are executed. If a rule matches, no immediate disruptive action is taken (e.g. the transaction is not blocked). Instead, the matched rule contributes to a transactional *anomaly score*, which acts as a running total. The rules just handle detection, adding to the anomaly score if they match. In addition, an individual matched rule will typically log a record of the match for later reference, including the ID of the matched rule, the data that caused the match, and the URI that was being requested.

Once all of the rules that inspect *request* data have been executed, *blocking evaluation* takes place. If the anomaly score is greater than or equal to the inbound anomaly score threshold then the transaction is *denied*. Transactions that are not denied continue on their journey.

![Diagram showing an example where the inbound anomaly score threshold is set to 5. A first example request accumulates an anomaly score of 2 and is allowed to pass at the blocking evaluation step. A second example request accumulates an anomaly score of 7 and is denied at the blocking evaluation step.](as_inbound_no_fonts.svg?height=36em)

Continuing on, once all of the rules that inspect *response* data have been executed, a second round of blocking evaluation takes place. If the *outbound* anomaly score is greater than or equal to the outbound anomaly score threshold then the transaction is *denied*.

{{% notice info %}}
Having separate inbound and outbound anomaly scores and thresholds allows for request data and response data to be inspected and scored independently.
{{% /notice %}}

### Summary of Anomaly Scoring Mode

To summarize, anomaly scoring mode in the CRS works like so:

1. Execute all *request* rules
1. Make a blocking decision using the *inbound* anomaly score threshold
1. Execute all *response* rules
1. Make a blocking decision using the *outbound* anomaly score threshold

### The Anomaly Scoring Mechanism In Action

As described, individual rules are only responsible for detection and inspection: they do not block or deny transactions. If a rule matches then it increments the anomaly score. This is done using ModSecurity's `setvar` action.

Below is an example of a detection rule which matches when a request has a `Content-Length` header field containing something other than digits. Notice the final line of the rule: it makes use of the `setvar` action, which will increment the anomaly score if the rule matches:

```apache
SecRule REQUEST_HEADERS:Content-Length "!@rx ^\d+$" \
    "id:920160,\
    phase:1,\
    block,\
    t:none,\
    msg:'Content-Length HTTP header is not numeric',\
    logdata:'%{MATCHED_VAR}',\
    tag:'application-multi',\
    tag:'language-multi',\
    tag:'platform-multi',\
    tag:'attack-protocol',\
    tag:'paranoia-level/1',\
    tag:'OWASP_CRS',\
    tag:'capec/1000/210/272',\
    ver:'OWASP_CRS/3.4.0-dev',\
    severity:'CRITICAL',\
    setvar:'tx.anomaly_score_pl1=+%{tx.critical_anomaly_score}'"
```

{{% notice info %}}
Notice that the anomaly score variable name has the suffix `pl1`. Internally, CRS keeps track of anomaly scores on a *per* [*paranoia level*]({{< ref "paranoia_levels" >}} "Page describing paranoia levels.") basis. The individual paranoia level anomaly scores are added together before each round of blocking evaluation takes place, allowing the total combined inbound or outbound score to be compared to the relevant anomaly score threshold.

Tracking the anomaly score per paranoia level allows for clever scoring mechanisms to be employed, such as the [executing paranoia level]({{< ref "paranoia_levels#moving-to-a-higher-paranoia-level" >}} "Section describing the executing paranoia level feature.") feature.
{{% /notice %}}

The rules files `REQUEST-949-BLOCKING-EVALUATION.conf` and `RESPONSE-959-BLOCKING-EVALUATION.conf` are responsible for executing the inbound (request) and outbound (response) rounds of blocking evaluation, respectively. The rules in these files calculate the total inbound or outbound transactional anomaly score and then make a blocking decision, by comparing the result to the defined threshold and taking blocking action if required.

## Configuring Anomaly Scoring Mode

The following settings can be configured when using anomaly scoring mode:

- Anomaly score thresholds
- Severity levels
- Early blocking

If using a native Core Rule Set installation on a web application firewall, these settings are defined in the file `crs-setup.conf`. If running CRS where it has been integrated into a commercial product or CDN then support varies. Some vendors expose these settings in the GUI while other vendors require custom rules to be written which set the necessary variables. Unfortunately, there are also vendors that don't allow these settings to be configured at all.

### Anomaly Score Thresholds

An anomaly score threshold is the cumulative anomaly score at which an inbound request or an outbound response will be blocked.

Most detected inbound threats carry an anomaly score of 5 (by default), while smaller violations, e.g. protocol and standards violations, carry lower scores. An anomaly score threshold of 7, for example, would require multiple rule matches in order to trigger a block (e.g. one "critical" rule scoring 5 plus a lesser-scoring rule, in order to reach the threshold of 7). An anomaly score threshold of 10 would require at least two "critical" rules to match, or a combination of many lesser-scoring rules. **Increasing the anomaly score thresholds makes the CRS less sensitive** and hence less likely to block transactions.

{{% notice warning %}}
Increasing the anomaly score thresholds may allow some attacks to bypass the CRS rules.
{{% /notice %}}

{{% notice tip %}}
A common practice when working with a **new** CRS deployment is to start in blocking mode from the very beginning with *very high anomaly score thresholds* (even as high as 10000). The thresholds can be gradually lowered over time as an iterative process.

This tuning method was developed and advocated by Christian Folini, who documented it in detail, along with examples, in a popular tutorial titled [Handling False Positives with the OWASP ModSecurity Core Rule Set](https://www.netnea.com/cms/apache-tutorial-8_handling-false-positives-modsecurity-core-rule-set/).
{{% /notice %}}

CRS uses two anomaly score thresholds, which can be defined using the variables listed below:

| Threshold                        | Variable                              |
| -------------------------------- | ------------------------------------- |
| Inbound anomaly score threshold  | `tx.inbound_anomaly_score_threshold`  |
| Outbound anomaly score threshold | `tx.outbound_anomaly_score_threshold` |

A simple way to set these thresholds is to uncomment and use rule 900110:

```apache
SecAction \
 "id:900110,\
  phase:1,\
  nolog,\
  pass,\
  t:none,\
  setvar:tx.inbound_anomaly_score_threshold=5,\
  setvar:tx.outbound_anomaly_score_threshold=4"
```

### Severity Levels

Each CRS rule has an associated *severity level*. Different severity levels have different anomaly scores associated with them. This means that different rules can increment the anomaly score by different amounts if the rules match.

The four severity levels and their *default* anomaly scores are:

| Severity Level | Default Anomaly Score |
| -------------- | --------------------- |
| **CRITICAL**   | 5                     |
| **ERROR**      | 4                     |
| **WARNING**    | 3                     |
| **NOTICE**     | 2                     |

For example, by default, a single matching `CRITICAL` rule would increase the anomaly score by 5, while a single matching `WARNING` rule would increase the anomaly score by 3.

The default anomaly scores are rarely ever changed. It is possible, however, to set custom anomaly scores for severity levels. To do so, uncomment rule 900100 and set the anomaly scores as desired:

```apache
SecAction \
 "id:900100,\
  phase:1,\
  nolog,\
  pass,\
  t:none,\
  setvar:tx.critical_anomaly_score=5,\
  setvar:tx.error_anomaly_score=4,\
  setvar:tx.warning_anomaly_score=3,\
  setvar:tx.notice_anomaly_score=2"
```

{{% notice info %}}
The CRS makes use of a ModSecurity feature called *macro expansion* to propagate the value of the severity level anomaly scores throughout the entire rule set.
{{% /notice %}}

### Early Blocking

TODO
