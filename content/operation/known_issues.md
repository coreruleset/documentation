---
title: Known Issues
weight: 10
disableToc: false
chapter: false
---

> There are some *known issues* with CRS and some of its compatible WAF engines. This page describes these issues. Get in touch if you think something is missing.

{{% notice warning %}}
There are still **false positives** for standard web applications in the default install (paranoia level 1). Please [report these on GitHub](https://github.com/coreruleset/coreruleset/issues/new/choose) if and when encountered.
{{% /notice %}}

👉 False positives from paranoia level 2 and higher are considered to be less interesting, as it is expected that users will write exclusion rules for their alerts in the higher paranoia levels. Nevertheless, false positives from higher paranoia levels can still be reported and the CRS project will try to find a generic solution for them.

### AH00111: Config variable ${...} is not defined

**Apache** may give an error on startup when the CRS is loaded:

```
AH00111: Config variable ${[^} is not defined
```

It appears that Apache tries to be smart by trying to evaluate a config variable. This notice should be a warning and can be safely ignored. The problem has been investigated and a solution has not been found yet.

### **ModSecurity 3.0.0-3.0.2** will give an error

```
Expecting an action, got: ctl:requestBodyProcessor=URLENCODED"`
```

Support for the URLENCODED body processor was only added in ModSecurity 3.0.3. To resolve this, upgrade to ModSecurity 3.0.3 or higher.

### Old Debian versions without YAJL

**Debian** releases up to and including Jessie lack YAJL/JSON support in ModSecurity. This causes the following error in the Apache ErrorLog or SecAuditLog:

```
ModSecurity: JSON support was not enabled.
```

JSON support was enabled in Debian's package version 2.8.0-4 (Nov 2014). To resolve this, it is possible to either use `backports.debian.org` to install the latest ModSecurity
release or to disable the rule with ID 200001.

### Apache 2.4 prior to 2.4.11 ###

Apache versions prior to 2.4.11 are affected by a bug in parsing multi-line configuration directives, which causes Apache to fail during startup with an error such as:

```plaintext
Error parsing actions: Unknown action: \\
Action 'configtest' failed.`
```

This bug is known to plague RHEL/Centos 7 below v7.4 or httpd v2.4.6 release 67 and Ubuntu 14.04 LTS users. (The original bug report can be found at <https://bz.apache.org/bugzilla/show_bug.cgi?id=55910\>).

By now you should not be using such an old web server. It is advisable to upgrade your Apache version. If upgrading is not possible, the CRS project provides a script in the `util/join-multiline-rules` directory which converts the rules into a format that works around the bug. This script must be re-run whenever the CRS rules are modified or updated.

### Support for `application/soap+xml`

As of CRS version 3.0.1, support has been added for the `application/soap+xml` MIME type by default, as specified in RFC 3902. **OF IMPORTANCE:** application/soap+xml is indicative that XML will be provided. In accordance with this, ModSecurity's XML request body processor should also be configured to support this MIME type. Within the ModSecurity project, [commit 5e4e2af](https://github.com/owasp-modsecurity/ModSecurity/commit/5e4e2af7a6f07854fee6ed36ef4a381d4e03960e) has been merged to support this endeavor. However, if running a modified or preexisting version of the modsecurity.conf file provided by this repository, it is a good idea to upgrade rule '200000' accordingly. The rule now appears as follows:

```
SecRule REQUEST_HEADERS:Content-Type "(?:application(?:/soap\+|/)|text/)xml" \
  "id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"
```

### `SecDisableBackendCompression` not supported in libmodsecurity3

All versions of libmodsecurity3 [do not support](https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v3.x)#secdisablebackendcompression) the `SecDisableBackendCompression` directive at all ###

If Nginx is acting as a proxy and the backend supports any type of compression, if the client sends an `Accept-Encoding: gzip,deflate,...` or `TE` header, the backend will return the response in a compressed format. Because of this, the engine cannot verify the response. As a workaround, you need to override the `Accept-Encoding` and `TE` headers in the proxy:

```nginx
server {
    server_name     foo.com;
    ...
    location / {
        proxy_pass         http://backend;
        ...
        proxy_set_header   Accept-Encoding "";
        proxy_set_header   TE "";
    }
}
```

### Anomaly Mode Doesn't Work

Sometimes on IIS or Nginx users run into an instance where anomaly mode doesn't work as expected. In fact upon careful inspection of logs one would notice that rules don't fire in the order we would expect. In general this is a result of using the `'*'` operator within these environments as it does not act the same way as in Apache. In general within both Apache and IIS one should expliticly include the various files present within the OWASP CRS instead of using the `'*'`.

### Webserver returns error after CRS install

This is likley due to a rule triggering. For instance in some cases a rule is enabled that prohibits access via an IP address. Depending on your [SecDefaultAction](<https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)#SecDefaultAction>) and [SecRuleEngine](<https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleEngine>) configurations, this may result in a redirect loop or a status code. If this is the problem you are experiencing you should consult your error.log (or event viewer for IIS). From this location you candetermine the offending rule and add an exception if neccessary see [false positives and tuning]({{< ref "../concepts/false_positives_tuning.md" >}}).
