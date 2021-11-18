---
title: "Anomaly Scoring"
chapter: false
weight: 10
---

> The Core Rule Set 3 is designed as an anomaly scoring rule set. This page explains what anomaly scoring is and how to use it.

## Overview of Anomaly Scoring

Anomaly scoring, also known as "collaborative detection", is a scoring mechanism used in the Core Rule Set. It assigns a numeric score to HTTP requests and responses, representing how 'anomalous' they appear to be. Anomaly scores can then be used to make blocking decisions. The default CRS blocking policy, for example, is to block any transaction that exceeds a defined anomaly score threshold.

## How Anomaly Scoring Mode Works

Anomaly scoring mode combines the concepts of *collaborative detection* and *delayed blocking*. The key idea to understand is that **the inspection/detection rule logic is decoupled from the blocking functionality**.

Individual rules designed to detect specific types of attacks and malicious behaviour are executed. If a rule matches, no immediate disruptive action is taken (e.g. the transaction is not blocked). Instead, the matched rule contributes to a transactional *anomaly score*, which acts as a running total. The rules just handle detection, adding to the anomaly score if they match. In addition, an individual matched rule will typically log a record of the match for later reference, including the ID of the matched rule, the data that caused the match, and the URI that was being requested.

Once all of the rules that inspect *request* data have been executed, *blocking evaluation* takes place. If the anomaly score is greater than or equal to the inbound anomaly score threshold then the transaction is *denied*. Transactions that are not denied continue on their journey.

![Diagram showing an example where the inbound anomaly score threshold is set to 5. A first example request accumulates an anomaly score of 7 and is denied at the blocking evaluation step. A second example request accumulates no anomaly score and is allowed to pass at the blocking evaluation step.](as_inbound_no_fonts.svg)

Continuing on, once all of the rules that inspect *response* data have been executed, a second round of blocking evaluation takes place. If the *outbound* anomaly score is greater than or equal to the outbound anomaly score threshold then the transaction is *denied*.

{{% notice info %}}
Having separate inbound and outbound anomaly scores and thresholds allows for request data and response data to be inspected and scored independently.
{{% /notice %}}

### Summary of Anomaly Scoring Mode

To summarise, anomaly scoring mode in the CRS works like so:

1. Execute all *request* rules
1. Make a blocking decision using the *inbound* anomaly score threshold
1. Execute all *response* rules
1. Make a blocking decision using the *outbound* anomaly score threshold

{{% notice warning %}}
From version 3.0 onwards, Anomaly Scoring is the default detection mode. Traditional detection mode is discouraged.
{{% /notice %}}

Within the `csr-setup.conf.example` you can control the following related CRS items:

-   Anomaly Scoring Severity Levels
-   Anomaly Scoring Threshold Levels (Blocking)
-   Enable/Disable Blocking
-   Choose the default logging actions
-   and much more!

Anomaly Scoring Mode
--------------------


### Configuring Anomaly Scoring Mode

The default mode in CRS 3.x is Anomaly Scoring mode, you can verify this
is your mode by checking that the SecDefaultAction line in the
csr-setup.conf file usees the pass action:

```apache
SecDefaultAction "phase:2,pass,log"
```

In this mode, each matched rule will not block, but rather will
increment anomaly scores using ModSecurity\'s setvar action. Here is an
example of an SQL Injection CRS rule that is using setvar actions to
increase both the overall anomaly score and the SQL Injection
sub-category score:

```apache
SecRule ARGS|REQUEST_COOKIES|QUERY_STRING|REQUEST_FILENAME "@detectSQLi" \
   "msg:'SQL Injection Attack Detected via LibInjection',\
   id:942100,\
   rev:'1',\
   ver:'OWASP_CRS/3.0.0',\
   maturity:'1',\
   accuracy:'8',\
   phase:request,\
   block,\
   multiMatch,\
   t:none,t:utf8toUnicode,t:urlDecodeUni,t:removeNulls,t:removeComments,\
   capture,\
   logdata:'Matched Data: %{TX.0} found within %{MATCHED_VAR_NAME}: %{MATCHED_VAR}',\
   tag:'application-multi',\
   tag:'language-multi',\
   tag:'platform-multi',\
   tag:'attack-sqli',\
   tag:'OWASP_CRS/WEB_ATTACK/SQL_INJECTION',\
   tag:'WASCTC/WASC-19',\
   tag:'OWASP_TOP_10/A1',\
   tag:'OWASP_AppSensor/CIE1',\
   tag:'PCI/6.5.2',\
   setvar:tx.anomaly_score=+%{tx.critical_anomaly_score},\
   setvar:tx.sql_injection_score=+%{tx.critical_anomaly_score},\
   setvar:'tx.msg=%{rule.msg}',setvar:tx.%{rule.id}-OWASP_CRS/WEB_ATTACK/SQL_INJECTION-%{matched_var_name}=%{matched_var}"
```

### Anomaly Scoring Severity Levels

Each rule has a severity level specified. We have updated the rules to
allow for the anomaly score collection incrementation to use macro
expansion. Below is a snippet from the above rule *(id:942100)* where that
occurs:

```apache
setvar:tx.anomaly_score=+%{tx.critical_anomaly_score},\
setvar:tx.sql_injection_score=+%{tx.critical_anomaly_score},\
```

This adds a variable amount, *tx.critical_anomaly_score*, to the current
anomaly scores. The user can configure what each score represents from
within the csr-setup.conf file and these scores will be propagated out
for use in the rules by using macro expansion. The following is an
excerpt from csr-setup.conf where that configuration is set:

```apache
#
# -=[ Anomaly Scoring Severity Levels ]=-
#
# These are the default scoring points for each severity level.  You may
# adjust these to you liking.  These settings will be used in macro expansion
# in the rules to increment the anomaly scores when rules match.
#
# These are the default Severity ratings (with anomaly scores) of the individual rules -
#
#    - 2: Critical - Anomaly Score of 5.
#         Is the highest severity level possible without correlation.  It is
#         normally generated by the web attack rules (40 level files).
#    - 3: Error - Anomaly Score of 4.
#         Is generated mostly from outbound leakage rules (50 level files).
#    - 4: Warning - Anomaly Score of 3.
#         Is generated by malicious client rules (35 level files).
#    - 5: Notice - Anomaly Score of 2.
#         Is generated by the Protocol policy and anomaly files.
#
setvar:tx.critical_anomaly_score=5, \
setvar:tx.error_anomaly_score=4, \
setvar:tx.warning_anomaly_score=3, \
setvar:tx.notice_anomaly_score=2"
```

This configuration would mean that every CRS rule that has a Severity
rating of "Critical" would increase the transactional anomaly score by
5 points per rule match. When we have a rule match, you can see how the
anomaly scoring works from within the `modsec_debug.log` file:

```text
...
Setting variable: tx.sql_injection_score=+%{tx.critical_anomaly_score}
Recorded original collection variable: tx.sql_injection_score = "0"
Resolved macro %{tx.critical_anomaly_score} to: 5
Relative change: sql_injection_score=0+5
Set variable "tx.sql_injection_score" to "5".
Setting variable: tx.anomaly_score=+%{tx.critical_anomaly_score}
Recorded original collection variable: tx.anomaly_score = "0"
Resolved macro %{tx.critical_anomaly_score} to: 5
Relative change: anomaly_score=0+5
Set variable "tx.anomaly_score" to "5".
...
```

Now that we have the capability to do anomaly scoring, the next step is
to set our thresholds. This is the score value at which, if the current
transactional score is above, it will be denied. We have various
different anomaly scoring thresholds to set for both specific
vulnerability types and generic requests/response levels. These will be
evaluated in two different files. Inbound request are evaluated at the
end of `phase:2` in the `rules/REQUEST-949-BLOCKING-EVALUATION.conf` file and
outbound responses are evaluated at the end of `phase:4` in the
`rules/RESPONSE-959-BLOCKING-EVALUATION.conf` file. The thresholds are
configured in the `csr-setup.conf` file.

```apache
SecAction \
 "id:'900003',\
  phase:1,\
  nolog,\
  pass,\
  t:none,\
  setvar:tx.sql_injection_score_threshold=15,\
  setvar:tx.xss_score_threshold=15,\
  setvar:tx.rfi_score_threshold=5,\
  setvar:tx.lfi_score_threshold=5,\
  setvar:tx.rce_score_threshold=5,\
  setvar:tx.command_injection_score_threshold=5,\
  setvar:tx.php_injection_score_threshold=5,\
  setvar:tx.http_violation_score_threshold=5,\
  setvar:tx.trojan_score_threshold=5,\
  setvar:tx.session_fixation_score_threshold=5,\
  setvar:tx.inbound_anomaly_score_threshold=5,\
  setvar:tx.outbound_anomaly_score_threshold=4"
```

With these current default settings, anomaly scoring mode will act
similarly to traditional mode from a blocking perspective. Since all
critical level rules increase the anomaly score by 5 points, this means
that even 1 critical level rule match will cause a block. If you want to
adjust the anomaly score so that you have a lower chance of blocking
non-malicious clients (false positives) you could raise the
tx.inbound_anomaly_score_level settings to something higher like 10
or 15. This would mean that two or more critical severity rules have
matched before you decide to block. Another advantage of this approach
is that you could aggregate multiple lower severity rule matches and
then decide to block. So, one lower severity rule match (such as missing
a Request Header such as Accept) would not result in a block but if
multiple anomalies are triggered then the request would be blocked.

### Enable/Disable Blocking

You are probably familiar with the SecRuleEngine directive which allows
you to control blocking mode (On) vs. Detection mode (DetectionOnly).
With the Anomaly Scoring mode, if you want to allow blocking, you should
set the SecRueEngine to On and then uncomment the following SecAction in
the csr-setup.conf file. Note: this is done by default in CRS 3.x:

```apache
SecAction \
 "id:'900004',\
  phase:1,\
  nolog,\
  pass,\
  t:none,\
  setvar:tx.anomaly_score_blocking=on"
```

When this rule is enabled, The rule within the
`rules/REQUEST-949-BLOCKING-EVALUATION.conf` and
`rules/RESPONSE-959-BLOCKING-EVALUATION.conf` files will evaluate the
anomaly scores at the end of the request/response phases and will block
the request if it exceeds a given anomaly threshold. An example of such
a rule is as follows:

```apache
SecRule TX:ANOMALY_SCORE "@ge %{tx.inbound_anomaly_score_threshold}" \
    "msg:'Inbound Anomaly Score Exceeded (Total Score: %{TX.ANOMALY_SCORE}, Last Matched Message: %{tx.msg}',\
    severity:CRITICAL,\
    phase:request,\
    id:949190,\
    t:none,\
    deny,\
    log,\
    tag:'application-multi',\
    tag:'language-multi',\
    tag:'platform-multi',\
    tag:'attack-generic',\
    setvar:tx.inbound_tx_msg=%{tx.msg},\
    setvar:tx.inbound_anomaly_score=%{tx.anomaly_score},\
    chain"
        SecRule TX:ANOMALY_SCORE_BLOCKING "@streq on" chain
            SecRule TX:/^\d+\-/ "(.*)"
```

Notice that there is an explicit deny within this rule. This explitly
listed disruptive action will override the default action of pass
(within anomaly mode)and block the transaction. If you would like a
different action to occur you would set it within the two
BLOCKING-EVALUATION files.

### Pros and Cons of Anomaly Scoring Detection Mode

Pros
- An increased confidence in blocking - since more detection rules
  contribute to the anomaly score, the higher the score, the more
  confidence you can have in blocking malicious transactions.
- Allows users to set a threshold that is appropriate for them -
  different sites may have different thresholds for blocking.
- Allows several low severity events to trigger alerts while
  individual ones are suppressed.
- One correlated event helps alert management.
- Exceptions may be handled by either increasing the overall anomaly
  score threshold, or by adding local custom exceptions file

Cons
- More complex for the average user.
- Log monitoring scripts may need to be updated for proper analysis

### Traditional Detection Mode (deprecated)

{{% notice warning %}}
Don't use this mode unless you have a ver specific need. You've been warned.
{{% /notice %}}

Traditional Detection Mode (or IDS/IPS mode) is the old default
operating mode. This is the most basic operating mode where all of the
rules are "self-contained". In this mode there is no intelligence is
shared between rules and each rule has no information about any previous
rule matches. That is to say, in this mode, if a rule triggers, it will
execute any disruptive/logging actions specified on the current rule.

### Configuring Traditional Mode

If you want to run the CRS in Traditional mode, you can do this easily
by modifying the SecDefaultAction directive in the csr-setup.conf file
to use a disruptive action other than the default \'pass\', such as
deny:

```apache
# Default (Anomaly Mode)
SecDefaultAction "phase:2,pass,log"
```

```apache
# Updated To Enable Traditional Mode
SecDefaultAction "phase:2,deny,status:403,log"
```

### Pros and Cons of Traditional Detection Mode

Pros

- The functionality of this mode is much easier for a new user to
  understand.
- Better performance (lower latency/resources) as the first disruptive
  match will stop further processing.

Cons

- Not all rules that could have triggered will be logged, only th
  first
- Not every site has the same risk tolerance
- Lower severity alerts may not trigger traditional mode
- Single low severity alerts may not be deemed critical enough to
  block, but multiple lower severity alerts in aggregate could be
