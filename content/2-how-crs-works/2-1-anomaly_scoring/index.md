---
title: Anomaly Scoring
weight: 21
disableToc: false
chapter: false
---

> CRS 3 is designed as an anomaly scoring rule set. This page explains what anomaly scoring is and how to use it.

## Overview of Anomaly Scoring

Anomaly scoring, also known as "collaborative detection", is a scoring mechanism used in CRS. It assigns a numeric score to HTTP transactions (requests and responses), representing how 'anomalous' they appear to be. Anomaly scores can then be used to make blocking decisions. The default CRS blocking policy, for example, is to block any transaction that meets or exceeds a defined anomaly score threshold.

## How Anomaly Scoring Mode Works

Anomaly scoring mode combines the concepts of *collaborative detection* and *delayed blocking*. The key idea to understand is that **the inspection/detection rule logic is decoupled from the blocking functionality**.

Individual rules designed to detect specific types of attacks and malicious behavior are executed. If a rule matches, no immediate disruptive action is taken (e.g. the transaction is not blocked). Instead, the matched rule contributes to a transactional *anomaly score*, which acts as a running total. The rules just handle detection, adding to the anomaly score if they match. In addition, an individual matched rule will typically log a record of the match for later reference, including the ID of the matched rule, the data that caused the match, and the URI that was being requested.

Once all of the rules that inspect *request* data have been executed, *blocking evaluation* takes place. If the anomaly score is greater than or equal to the inbound anomaly score threshold then the transaction is *denied*. Transactions that are not denied continue on their journey.

![Diagram showing an example where the inbound anomaly score threshold is set to 5. A first example request accumulates an anomaly score of 2 and is allowed to pass at the blocking evaluation step. A second example request accumulates an anomaly score of 7 and is denied at the blocking evaluation step.](as_inbound_no_fonts.svg?height=36em)

Continuing on, once all of the rules that inspect *response* data have been executed, a second round of blocking evaluation takes place. If the *outbound* anomaly score is greater than or equal to the outbound anomaly score threshold, then the response is *not returned* to the user. (Note that in this case, the request *is* fully handled by the backend or application; only the response is stopped.)

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
Notice that the anomaly score variable name has the suffix `pl1`. Internally, CRS keeps track of anomaly scores on a *per* [*paranoia level*]({{< ref "2-2-paranoia_levels" >}} "Page describing paranoia levels.") basis. The individual paranoia level anomaly scores are added together before each round of blocking evaluation takes place, allowing the total combined inbound or outbound score to be compared to the relevant anomaly score threshold.

Tracking the anomaly score per paranoia level allows for clever scoring mechanisms to be employed, such as the [executing paranoia level]({{< ref "2-2-paranoia_levels#moving-to-a-higher-paranoia-level" >}} "Section describing the executing paranoia level feature.") feature.
{{% /notice %}}

The rules files `REQUEST-949-BLOCKING-EVALUATION.conf` and `RESPONSE-959-BLOCKING-EVALUATION.conf` are responsible for executing the inbound (request) and outbound (response) rounds of blocking evaluation, respectively. The rules in these files calculate the total inbound or outbound transactional anomaly score and then make a blocking decision, by comparing the result to the defined threshold and taking blocking action if required.

## Configuring Anomaly Scoring Mode

The following settings can be configured when using anomaly scoring mode:

- Anomaly score thresholds
- Severity levels
- Early blocking

If using a native CRS installation on a web application firewall, these settings are defined in the file `crs-setup.conf`. If running CRS where it has been integrated into a commercial product or CDN then support varies. Some vendors expose these settings in the GUI while other vendors require custom rules to be written which set the necessary variables. Unfortunately, there are also vendors that don't allow these settings to be configured at all.

### Anomaly Score Thresholds

An anomaly score threshold is the cumulative anomaly score at which an inbound request or an outbound response will be blocked.

Most detected inbound threats carry an anomaly score of 5 (by default), while smaller violations, e.g. protocol and standards violations, carry lower scores. An anomaly score threshold of 7, for example, would require multiple rule matches in order to trigger a block (e.g. one "critical" rule scoring 5 plus a lesser-scoring rule, in order to reach the threshold of 7). An anomaly score threshold of 10 would require at least two "critical" rules to match, or a combination of many lesser-scoring rules. **Increasing the anomaly score thresholds makes the CRS less sensitive** and hence less likely to block transactions.

Rule coverage should be taken into account when setting anomaly score thresholds. Different CRS rule categories feature different numbers of rules. SQL injection, for example, is covered by more than 50 rules. As a result, a real world SQLi attack can easily gain an anomaly score of 15, 20, or even more. On the other hand, a rare protocol attack might only be covered by a single, specific rule. If such an attack only causes the one specific rule to match then it will only gain an anomaly score of 5. If the inbound anomaly score threshold is set to anything higher than 5 then attacks like the one described will not be stopped. **As such, a CRS installation should aim for an inbound anomaly score threshold of 5.**

{{% notice warning %}}
Increasing the anomaly score thresholds may allow some attacks to bypass the CRS rules.
{{% /notice %}}

{{% notice info %}}
An outbound anomaly score threshold of 4 (the default) will block a transaction if any single response rule matches.
{{% /notice %}}

{{% notice tip %}}
A common practice when working with a **new** CRS deployment is to start in blocking mode from the very beginning with *very high anomaly score thresholds* (even as high as 10000). The thresholds can be gradually lowered over time as an iterative process.

This tuning method was developed and advocated by Christian Folini, who documented it in detail, along with examples, in a popular tutorial titled [Handling False Positives with OWASP CRS](https://www.netnea.com/cms/apache-tutorial-8_handling-false-positives-modsecurity-core-rule-set/).
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

Early blocking is an optional setting which can be enabled to allow blocking decisions to be made earlier than usual.

As summarized previously, anomaly scoring mode works like so:

1. Execute all *request* rules
1. Make a **blocking decision** using the *inbound* anomaly score threshold
1. Execute all *response* rules
1. Make a **blocking decision** using the *outbound* anomaly score threshold

The early blocking option takes advantage of the fact that the request and response rules are actually split across different *phases*. A more detailed overview of anomaly scoring mode looks like so:

1. Execute all phase 1 *(request header)* rules
1. Execute all phase 2 *(request body)* rules
1. Make a **blocking decision** using the *inbound* anomaly score threshold
1. Execute all phase 3 *(response header)* rules
1. Execute all phase 4 *(response body)* rules
1. Make a **blocking decision** using the *outbound* anomaly score threshold

More data from a transaction becomes available for inspection in each subsequent processing phase. In phase 1 the request headers are available for inspection. Detection rules that are only concerned with request headers are executed here. In phase 2 the request body also becomes available for inspection. Rules that need to inspect the request body, perhaps in addition to request headers, are executed here.

If a transaction's anomaly score *already* meets or exceeds the inbound anomaly score threshold by the end of phase 1 (due to causing phase 1 rules to match) then, in theory, the phase 2 rules don't need to be executed. This saves the time and resources it would take to process the detection rules in phase 2 and also protects the server from being attacked when handling the body of the request. The majority of CRS rules take place in phase 2, which is also where the request body inspection rules are located. When dealing with large request bodies, it may be worthwhile to avoid executing the phase 2 rules in this way. The same logic applies to blocking *responses* that have already met the *outbound* anomaly score threshold in phase 3, *before* reaching phase 4. This saves the time and resources required to execute the phase 4 rules, which inspect the response body.

Early blocking makes this possible by inserting **two additional rounds of blocking evaluation**: one after the phase 1 detection rules have finished executing, and another after the phase 3 detection rules:

1. Execute all phase 1 *(request header)* rules
1. Make an **early blocking decision** using the *inbound* anomaly score threshold
1. Execute all phase 2 *(request body)* rules
1. Make a **blocking decision** using the *inbound* anomaly score threshold
1. Execute all phase 3 *(response header)* rules
1. Make an **early blocking decision** using the *outbound* anomaly score threshold
1. Execute all phase 4 *(response body)* rules
1. Make a **blocking decision** using the *outbound* anomaly score threshold

{{% notice info %}}
More information about processing phases can be found in the [processing phases section](https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)#processing-phases) of the ModSecurity Reference Manual.
{{% /notice %}}

{{% notice warning %}}
The early blocking option has a major drawback to be aware of: **it can cause potential alerts to be hidden**.

If a transaction is blocked early then its body is not inspected. For example, if a transaction is blocked early at the end of phase 1 (the request headers phase) then the body of the request is never inspected. If the early blocking option is *not* enabled, it's possible that such a transaction would proceed to cause phase 2 rules to match. Early blocking hides these potential alerts. The same applies to responses that trigger an early block: it's possible that some phase 4 rules would match if early blocking were not enabled.

Using the early blocking option results in having less information to work with, due to fewer rules being executed. This may mean that the full picture is not present in log files when looking back at attacks and malicious traffic. It can also be a problem when dealing with false positives: tuning away a false positive in phase 1 will allow the same request to proceed to the next phase the next time it's issued (instead of being blocked at the end of phase 1). The problem is that now, with the request making it past phase 1, more, previously "hidden" false positives may appear in phase 2.
{{% /notice %}}

{{% notice warning %}}
If early blocking is not enabled, there's a chance that the web server will interfere with the handling of a request between phases 1 and 2. Take the example where the Apache web server issues a redirect to a new location. With a request that violates CRS rules in phase 1, this may mean that the request has a higher anomaly score than the defined threshold but it gets redirected away before blocking evaluation happens.
{{% /notice %}}

#### Enabling the Early Blocking Option

If using a native CRS installation on a web application firewall, the early blocking option can be enabled in the file `crs-setup.conf`. This is done by uncommenting rule 900120, which sets the variable `tx.blocking_early` to 1 in order to enable early blocking. CRS otherwise gives this variable a default value of 0, meaning that early blocking is disabled by default.

```apache
SecAction \
  "id:900120,\
  phase:1,\
  nolog,\
  pass,\
  t:none,\
  setvar:tx.blocking_early=1"
```

If running CRS where it has been integrated into a commercial product or CDN then support for the early blocking option varies. Some vendors may allow it to be enabled through the GUI, through a custom rule, or they might not allow it to be enabled at all.
