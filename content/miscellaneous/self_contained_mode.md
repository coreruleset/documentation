---
title: Self-Contained Mode
weight: 10
disableToc: false
chapter: false
---

## Self-Contained Mode

### Traditional Detection Mode (deprecated)

The default mode in CRS 3.x is Anomaly Scoring mode, you can verify this
is your mode by checking that the SecDefaultAction line in the
crs-setup.conf file usees the pass action:

```apache
SecDefaultAction "phase:2,pass,log"
```

{{% notice warning %}}
From version 3.0 onwards, Anomaly Scoring is the default detection mode. Traditional detection mode is discouraged.
{{% /notice %}}

(AH) Summary: traditional, self-contained mode: a rule match (alert) causes an immediate block.

Traditional Detection Mode (or IDS/IPS mode) is the old default
operating mode. This is the most basic operating mode where all of the
rules are "self-contained". In this mode there is no intelligence is
shared between rules and each rule has no information about any previous
rule matches. That is to say, in this mode, if a rule triggers, it will
execute any disruptive/logging actions specified on the current rule.

### Configuring Traditional Mode

If you want to run the CRS in Traditional mode, you can do this easily
by modifying the SecDefaultAction directive in the crs-setup.conf file
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
- Better performance (lower latency and resource usage) as the first disruptive
  match will stop further processing.

Cons

- Not all rules are executed, so not all rules that *could* have been
  triggered will match. As such, logging information on a successful
  block is less useful, as only the first detected threat is logged
- Not every site has the same risk tolerance
- Lower severity alerts may not trigger traditional mode
- Single low severity alerts may not be deemed critical enough to
  block, but multiple lower severity alerts in aggregate could be

### Pros and Cons of Anomaly Scoring Detection Mode

Pros
- An increased confidence in blocking - since more detection rules
  contribute to the anomaly score, the higher the score, the more
  confidence you can have in blocking malicious transactions.
- Flexibility for setting blocking policies. Allows users to set a threshold that is appropriate for them -
  different sites may have different thresholds for blocking.
- Allows several low severity events to trigger alerts while
  individual ones are suppressed.
- One correlated event helps alert management.
- Exceptions may be handled by either increasing the overall anomaly
  score threshold, or by adding local custom exceptions file
- More accurate log information, as all rules execute

Cons
- More complex for the average user.
- Log monitoring scripts may need to be updated for proper analysis
