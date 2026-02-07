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

## ModSecurity's `--disable-request-early`

> **Warning: Disabling early execution of phase 1 rules**
> By default, ModSecurity **enables** early request processing, allowing phase 1 rules to execute during the early stages of request handling. Using the `--disable-request-early` compilation flag **disables** this behavior and can cause serious compatibility issues with CRS 4.0+.

### ⚙️ Motivation

- During the [CRS Monthly Chat on **May 5, 2025**](https://github.com/coreruleset/coreruleset/issues/4116), the development team agreed to officially document this flag following reports that disabling it leads to unexpected behavior, particularly with rule initialization and processing in certain webserver contexts.
- Early request processing is **enabled by default**. Disabling it with `--disable-request-early` can trigger critical issues as documented in [CRS issue #3696](https://github.com/coreruleset/coreruleset/issues/3696) and [ModSecurity issue #3362](https://github.com/owasp-modsecurity/ModSecurity/issues/3362).

### 🧩 How it works

- With the default behavior (early request processing **enabled**), phase 1 rules execute during the early request hook, ensuring proper initialization of CRS variables and thresholds.
- When compiled with `--disable-request-early`, phase 1 rules are moved to a later hook. This prevents proper initialization in certain contexts (such as Apache's `RedirectMatch` at virtual host scope), causing CRS to malfunction.

> 💡 Note: Historically introduced in the 2.x version of ModSecurity. The default is to have early request processing **enabled**, and this should not be changed for CRS 4.0+ compatibility.

### 🔐 Risks and Trade‑offs

| Potential Issue | Details |
|-----------------|---------|
| **Initialization failure** | Phase 1 rules may not execute in all request contexts (e.g., Apache redirects), leaving CRS variables uninitialized and causing 403 errors or bypasses. |
| **CRS 4.0+ incompatibility** | CRS 4.0 and later versions rely on early request processing for proper anomaly score threshold initialization. Disabling this breaks core functionality. |
| **Context mismatch** | In Apache with `RedirectMatch` or similar directives at virtual host scope, phase 1 may be completely skipped, rendering CRS non-functional. |

These issues were reported by users who compiled ModSecurity with `--disable-request-early` and subsequently experienced CRS failures.

### 🧭 Recommendations

- **Do NOT use `--disable-request-early`** when compiling ModSecurity. Keep the default behavior (early request processing enabled).
- If you are experiencing issues with CRS 4.0+, verify that your ModSecurity installation was not compiled with `--disable-request-early`.
- CRS 4.0 and later versions **require** early request processing to function correctly.

### 🛠️ Verifying your ModSecurity configuration

If you suspect your ModSecurity was compiled with early request processing disabled, you will need to recompile it with the default settings:

```bash
./configure  # Do NOT use --disable-request-early
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
  Action 'configtest' failed.
  ```

  This bug is known to plague RHEL/Centos 7 below v7.4 or httpd v2.4.6 release 67 and Ubuntu 14.04 LTS users. (The original bug report can be found [here](https://bz.apache.org/bugzilla/show_bug.cgi?id=55910)).

  It is recommended to upgrade an affected Apache version. If upgrading is not possible, the CRS project provided a script in older versions (CRS v3.x) which converts the rules into a format that works around the bug. This script must be re-run whenever the CRS rules are modified or updated.


## ModSecurity

👉 versions **3.0.0-3.0.2** will give an error:

  ```
  Expecting an action, got: ctl:requestBodyProcessor=URLENCODED"
  ```

  Support for the URLENCODED body processor was only added in ModSecurity 3.0.3.
  :warning: Please do not use such an older version of ModSecurity. Upgrade to the latest and greatest.

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
If Nginx is acting as a proxy and the backend supports any type of compression, then if the client sends an `Accept-Encoding: gzip,deflate,...` or `TE` header, then the backend will return the response in a compressed format. Because of this, the engine cannot verify the response. As a workaround, you need to override the `Accept-Encoding` and `TE` headers in the proxy:

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
