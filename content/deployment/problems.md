---
title: "Problems with installation"
menuTitle: "Problems"
chapter: false
weight: 30
---

These have happened in some installs in the past. We are collecting them here for you to have them 

### Apache Line Continuation

For really old versions of Apache, that come with some major distributions In Apache 2.4.x before 2.4.11 there is a bug where the use of linecontinuations in a config size may cause the line continuation to be truncated. This will lead to an error similar to the following:

```bash
Syntax error on line 24 of /etc/httpd/modsecurity.d/activated_rules/RESPONSE-50-DATA-LEAKAGES-PHP.conf:
Error parsing actions: Unknown action: \
```

This is not an error with ModSecurity or OWASP CRS. In order to fix this issue you can simply add a space before the continuation on the offending line. For more information see [apache bugzilla](https://bz.apache.org/bugzilla/show_bug.cgi?id=55910).

### Anomaly Mode Doesn't Work

Sometimes on IIS or Nginx users run into an instance where anomaly mode doesn't work as expected. In fact upon careful inspection of logs one would notice that rules don't fire in the order we would expect. In general this is a result of using the `'*'` operator within these environments as it does not act the same way as in Apache. In general within both Apache and IIS one should expliticly include the various files present within the OWASP CRS instead of using the `'*'`.

### Webserver returns error after CRS install

This is likley due to a rule triggering. For instance in some cases a rule is enabled that prohibits access via an IP address. Depending on your [SecDefaultAction](<https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)#SecDefaultAction>) and [SecRuleEngine](<https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleEngine>) configurations, this may result in a redirect loop or a status code. If this is the problem you are experiencing you should consult your error.log (or event viewer for IIS). From this location you candetermine the offending rule and add an exception if neccessary see [false positives and tuning]({{< ref "../concepts/false_positives_tuning.md" >}}).
