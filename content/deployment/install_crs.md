---
title: "Installing the Core Rule Set"
weight: 16
disableToc: false
chapter: false
---

> All the information needed to properly install CRS is presented on this page.

## Downloading the OWASP Core Rule Set

With a compatible WAF engine installed and working, the next step is typically to download and install the OWASP CRS. The CRS project strongly recommends using a [supported version](https://github.com/coreruleset/coreruleset/security/policy).

Official CRS releases can be found at the following URL: https://github.com/coreruleset/coreruleset/releases.

For *production* environments, it is recommended to use the latest release, which is v{{< param crs_latest_release >}}. For *testing* the bleeding edge CRS version, nightly releases are also provided.

### Verifying Releases

{{% notice note %}}
Releases are signed using the CRS project's [GPG key](https://coreruleset.org/security.asc) (fingerprint: 3600 6F0E 0BA1 6783 2158 8211 38EE ACA1 AB8A 6E72). Releases can be verified using GPG/PGP compatible tooling.

To retrieve the CRS project's public key from public key servers using `gpg`, execute: `gpg --keyserver pgp.mit.edu --recv 0x38EEACA1AB8A6E72` (this ID should be equal to the last sixteen hex characters in the fingerprint).

It is also possible to use `gpg --fetch-key https://coreruleset.org/security.asc` to retrieve the key directly.
{{% /notice %}}

The following steps assume that a \*nix operating system is being used. Installation is similar on Windows but likely involves using a zip file from the CRS [releases page](https://github.com/coreruleset/coreruleset/releases).

To download the release file and the corresponding signature:

```bash
wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v{{< param crs_latest_release >}}.tar.gz
wget https://github.com/coreruleset/coreruleset/releases/download/v{{< param crs_latest_release >}}/coreruleset-{{< param crs_latest_release >}}.tar.gz.asc
```

To verify the integrity of the release:

```bash
gpg --verify coreruleset-{{< param crs_latest_release >}}.tar.gz.asc v{{< param crs_latest_release >}}.tar.gz
gpg: Signature made Wed Jun 30 10:05:48 2021 -03
gpg:                using RSA key 36006F0E0BA167832158821138EEACA1AB8A6E72
gpg: Good signature from "OWASP Core Rule Set <security@coreruleset.org>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 3600 6F0E 0BA1 6783 2158  8211 38EE ACA1 AB8A 6E72
```

If the signature was good then the verification succeeds. If a warning is displayed, like the above, it means the CRS project's public key is *known* but is not *trusted*.

To trust the CRS project's public key:

```bash
gpg edit-key 36006F0E0BA167832158821138EEACA1AB8A6E72
gpg> trust
Your decision: 5 (ultimate trust)
Are you sure: Yes
gpg> quit
```

The result when verifying a release will then look like so:

```bash
gpg --verify coreruleset-3.3.2.tar.gz.asc v3.3.2.tar.gz
gpg: Signature made Wed Jun 30 15:05:48 2021 CEST
gpg:                using RSA key 36006F0E0BA167832158821138EEACA1AB8A6E72
gpg: Good signature from "OWASP Core Rule Set <security@coreruleset.org>" [ultimate]
```

With the CRS release downloaded and verified, the rest of the set up can continue.

## Setting Up OWASP CRS

OWASP CRS contains a setup file that should be reviewed prior to completing set up. The setup file is the only configuration file within the root 'coreruleset-{{< param crs_latest_release >}}' folder and is named `crs-setup.conf.example`. Examining this configuration file and reading what the different options are is **highly** recommended.

At a minimum, keep in mind the following:

- CRS does not configure features such as the rule engine, audit engine, logging, etc. This task is part of the initial *engine* setup and is not a job for the rule set. For ModSecurity, if not already done, see the [recommended configuration](https://github.com/SpiderLabs/ModSecurity/blob/master/modsecurity.conf-recommended).
- Decide what ModSecurity should do when it detects malicious activity, e.g., drop the packet, return a *403 Forbidden* status code, issue a redirect to a custom page, etc.
- Make sure to configure the anomaly scoring thresholds. For more information see [Anomaly]({{< ref "anomaly_scoring.md" >}} "Anomaly").
- By default, the CRS rules will consider many issues with different databases and languages. If running in a specific environment, e.g., without any SQL database services present, it is probably a good idea to limit this behavior for performance reasons.
- Make sure to add any HTTP methods, static resources, content types, or file extensions that are needed, beyond the default ones listed.

Once reviewed and configured, the CRS configuration file should be renamed by changing the file suffix from `.example` to `.conf`:

```bash
mv crs-setup.conf.example crs-setup.conf
```

In addition to `crs-setup.conf.example`, there are two other ".example" files within the CRS repository. These are:

- `rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example`
- `rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example`

These files are designed to provide the rule maintainer with the ability to modify rules (see [false positives and tuning]({{< ref "../concepts/false_positives_tuning.md" >}}#rule-exclusions)) without breaking forward compatibility with rule set updates. These two files should be renamed by removing the `.example` suffix. This will mean that installing updates will *not* overwrite custom rule exclusions. To rename the files in Linux, use a command similar to the following:

```bash
mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
```

## Proceeding with the Installation

The engine should support the `Include` directive out of the box. This directive tells the engine to parse *additional* files for directives. The question is where to put the CRS rules folder in order for it to be included.

Looking at the CRS files, there are quite a few ".conf" files. While the names attempt to do a good job at describing what each file does, additional information is available in the [rules]({{< ref "../rules/" >}}) section.

### Includes for Apache

It is recommended to create a folder specifically to contain the CRS rules. In the example presented here, a folder named `modsecurity.d` has been created and placed within the root `<web server config>/` directory. When using Apache, wildcard notation can be used to vastly simplify the `Include` rules. Simply copying the cloned directory into the `modsecurity.d` folder and specifying the appropriate `Include` directives will install OWASP CRS. In the example below, the `modsecurity.conf` file has also been included, which includes recommended configurations for ModSecurity.

```apache
<IfModule security2_module>
        Include modsecurity.d/modsecurity.conf
        Include modsecurity.d/coreruleset-{{< param crs_latest_release >}}/crs-setup.conf
        Include modsecurity.d/coreruleset-{{< param crs_latest_release >}}/rules/*.conf
</IfModule>
```

### Includes for Nginx

Nginx will include files from the Nginx configuration directory (`/etc/nginx` or `/usr/local/nginx/conf/`, depending on the environment). Because only one `ModSecurityConfig` directive can be specified within `nginx.conf`, it is recommended to name that file `modsec_includes.conf` and include additional files from there. In the example below, the cloned `owasp-modsecurity-crs` folder was copied into the Nginx configuration directory. From there, the appropriate include directives are specified which will include OWASP CRS when the server is restarted. In the example below, the `modsecurity.conf` file has also been included, which includes recommended configurations for ModSecurity.

```nginx
include modsecurity.conf
{{% crsfiles prefix="include coreruleset-" version="3.3.2" %}}
``` 

## Verifying that the CRS is Active

Always verify that CRS is installed correctly by sending a 'malicious' request to your site or application, for instance:

```bash
curl 'https://www.example.com/?foo=/etc/passwd&bar=/bin/sh'
```

Depending on your configurated thresholds, this should be detected as a malicious request. If you use blocking mode, you should receive an Error 403. The request should also be logged to the audit log, which is usually in `/var/log/modsec_audit.log`.
