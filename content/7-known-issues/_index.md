---
title: Known Issues
weight: 7
pre: "<b>7. </b>"
disableToc: false
chapter: true
aliases: ["../operation/known_issues"]
---

> There are some *known issues* with CRS and some of its compatible WAF engines. This page describes these issues. Get in touch if you think something is missing.

- There are still **false positives** for standard web applications in the default install (paranoia level 1). Please [report these on GitHub](https://github.com/coreruleset/coreruleset/issues/new/choose) if and when encountered.

  False positives from paranoia level 2 and higher are considered to be less interesting, as it is expected that users will write exclusion rules for their alerts in the higher paranoia levels. Nevertheless, false positives from higher paranoia levels can still be reported and the CRS project will try to find a generic solution for them.

## ModSecurity's `--enable-request-early`

> **Enable early execution of phase 1 rules**  
> By default, ModSecurity does **not** activate this flag. Phase 1 rules run **after** the request headers are fully read. This flag allows certain phase 1 rules to trigger *earlier*, potentially before the full header set is available.

### ⚙️ Motivation

- During the [CRS Monthly Chat on **May 5, 2025**](https://github.com/coreruleset/coreruleset/issues/4116), the development team agreed to officially document this flag following concerns that enabling it may lead to unexpected behavior, particularly with rule ordering and header processing in certain webserver contexts.
- This setting is disabled by default and can trigger issues aligned with discussion in CRS issue https://github.com/coreruleset/coreruleset/issues/3696.

### 🧩 How it works

- Without the flag, all phase 1 rules run once the full request headers have been received.
- With `--enable-request-early`, some phase 1 rules may run sooner—immediately after preliminary parts of header parsing, before the complete header set is finalized.

> 💡 Note: Historically introduced in the 2.x version of ModSecurity but **not fully documented** in `./configure --help`

### 🔐 Risks and Trade‑offs

| Potential Issue | Details |
|-----------------|---------|
| **Header fragmentation** | Running rules early may miss later header fields or trigger unwanted matches on partial header state. |
| **Ordering issues** | Rule evaluation may happen in a different order than intended, throwing off downstream logic or causing false positives/negatives. |
| **Context mismatch** | In certain environments (e.g., Nginx, Apache with `Location` context), early execution may break assumptions about available variables or phase structure. |

These were precisely the unintended behaviors noted during the CRS chat.

### 🧭 Recommendations

- **Keep it disabled** (default). Only enable it if you fully understand rule timing and are crafting a custom setup that specifically requires early matching.
- Thoroughly **test your CRS configuration** under various edge cases and server contexts before enabling this flag in production.

### 🛠️ Enabling the flag

```bash
./configure --enable-request-early
make
make install
```

# Older known issues

## Apache

👉 may give an error on startup when the CRS is loaded:

  ```
  AH00111: Config variable ${[^} is not defined
  ```

  It appears that Apache tries to be smart by trying to evaluate a config variable. This notice should be a warning and can be safely ignored. The problem has been investigated and a solution has not been found yet.

👉 **Apache 2.4 prior to 2.4.11** is affected by a bug in parsing multi-line configuration directives, which causes Apache to fail during startup with an error such as:

  ```plaintext
  Error parsing actions: Unknown action: \\
  Action 'configtest' failed.`
  ```

  This bug is known to plague RHEL/Centos 7 below v7.4 or httpd v2.4.6 release 67 and Ubuntu 14.04 LTS users. (The original bug report can be found [here](https://bz.apache.org/bugzilla/show_bug.cgi?id=55910)).

  It is advisable to upgrade an affected Apache version. If upgrading is not possible, the CRS project provides a script in the `util/join-multiline-rules` directory which converts the rules into a format that works around the bug. This script must be re-run whenever the CRS rules are modified or updated.


## ModSecurity

👉 versions **3.0.0-3.0.2** will give an error:

  ```
  Expecting an action, got: ctl:requestBodyProcessor=URLENCODED"`
  ```

  Support for the URLENCODED body processor was only added in ModSecurity 3.0.3.
  :warning: Please do not use such an older version of ModSecurity. Upgrade to latest and greatest.

## Debian

👉 releases up to and including Jessie lack YAJL/JSON support in ModSecurity. This causes the following error in the Apache ErrorLog or SecAuditLog:

  ```
  ModSecurity: JSON support was not enabled.
  ```

  JSON support was enabled in Debian's package version 2.8.0-4 (Nov 2014). To solve this, it is possible to either use `backports.debian.org` to install the latest ModSecurity
  release or to disable the rule with ID 200001.

## CRS + ModSecurity

👉 As of CRS version 3.0.1, support has been added for the `application/soap+xml` MIME type by default, as specified in RFC 3902.

{{% notice note %}}
application/soap+xml is indicative that XML will be provided. In accordance with this, ModSecurity's XML request body processor should also be configured to support this MIME type. Within the ModSecurity project, [commit 5e4e2af](https://github.com/owasp-modsecurity/ModSecurity/commit/5e4e2af7a6f07854fee6ed36ef4a381d4e03960e) has been merged to support this endeavor. However, if running a modified or preexisting version of the modsecurity.conf file provided by this repository, it is a good idea to upgrade rule '200000' accordingly. The rule now appears as follows:

  ```
  SecRule REQUEST_HEADERS:Content-Type "(?:application(?:/soap\+|/)|text/)xml" \
    "id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"
  ```
{{% /notice %}}

## libmodsecurity3

[There is no support](https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v3.x)#secdisablebackendcompression) for the `SecDisableBackendCompression` directive at all. 
If Nginx is acting as a proxy and the backend supports any type of compression, if the client sends an `Accept-Encoding: gzip,deflate,...` or `TE` header, the backend will return the response in a compressed format. Because of this, the engine cannot verify the response. As a workaround, you need to override the `Accept-Encoding` and `TE` headers in the proxy:

   ```
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
