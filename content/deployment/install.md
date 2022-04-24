---
title: "Extended Install"
chapter: false
disableToc: false
weight: 20
---

If you need mode information than the one in the [quick start guide]({{< ref "quick_start.md" >}}), here we extend with additional details so keep reading.

Below you should find all the information you need to properly install CRS. If you are having problems feel free to reach out to our [Google Group](https://groups.google.com/a/owasp.org/forum/#!forum/modsecurity-core-rule-set-project), or our [Slack Channel](https://owasp.slack.com/archives/CBKGH8A5P). If you don't have access yet, [get your invite here](https://owasp.org/slack/invite).

## Prerequisites

Installing the CRS isn't very hard but it does have one major requirement: a compatible engine. The base reference engine shown here is ModSecurity.

{{% notice warning %}}
In order to run the CRS `3.x` using ModSecurity we recommend you to use the latest version available. For Nginx please use the `3.x` branch of ModSecurity, and for Apache use the latest `2.x` branch.
{{% /notice %}}

## How to install a compatible engine

Here we will cover two different ways of getting your engine up and running: you can use your favorite engine provided by your OS distribution, or it can be compiled from source. Here we will cover ModSecurity installs, but you can see the Coraza install documents [here](https://www.coraza.io).

### Installing ModSecurity

Pre-packaged modsecurity can be get from major Linux distributions.

- Debian: our friends at [DigitalWave](https://modsecurity.digitalwave.hu) package and most importantly **keep ModSecurity updated** for debian and derivatives, so check their repo!
- Fedora:
  - `dnf install mod_security` for Apache + ModSecurity2
- RHEL compatible: you will need to install EPEL and then `yum install mod_security`.

For Windows, get the latest MSI package from https://github.com/SpiderLabs/ModSecurity/releases.

{{% notice tip %}}
**Distributions might not update their releases frequently** 

As a result it is quite likely that your distribution may be missing required features or possibly even have security vulnerabilities. Additionally, depending on your package/package manager your ModSecurity configuration will be laid out slightly different.
{{% /notice %}}

As the different engines and distributions have differeent layouts for their configuration, and to simplify our documentation, we will use the prefix `<web server config>/` from now on.

Examples of this `<web server config>/` are:
- `/etc/apache2` in Debian and derivatives
- `/etc/httpd` in RHEL and derivatives
- `/usr/local/apache2` if you compiled apache from source with the default prefix
- `C:\Program Files\ModSecurity IIS\` (or Program Files(x86) depending on your configuration) on Windows
- `/etc/nginx`

### Compiling ModSecurity

Compiling ModSecurity is easy, but slightly outside the scope of this document. If you are interested in learning how to compile ModSecurity please go to the [ModSecurity documentation](https://github.com/SpiderLabs/ModSecurity/wiki). Having compiled ModSecurity there is a simple test to see if your installation is working. If you have compiled from source you would need to include the directive to **load your module** in your Web Server.

Examples:
- apache: `LoadModule security2_module modules/mod_security2.so`
- nginx: `load_module modules/ngx_http_modsecurity_module.so;`

Now you restart your server and modsecurity should output that it is being used. Examples:
```
2022/04/21 23:45:52 [notice] 1#1: ModSecurity-nginx v1.0.2 (rules loaded inline/local/remote: 0/6/0)
```
Apache shows:
```
[Thu Apr 21 23:55:35.142945 2022] [:notice] [pid 2528:tid 140410548673600] ModSecurity for Apache/2.9.3 (http://www.modsecurity.org/) configured.
[Thu Apr 21 23:55:35.142980 2022] [:notice] [pid 2528:tid 140410548673600] ModSecurity: APR compiled version="1.6.5"; loaded version="1.6.5"
[Thu Apr 21 23:55:35.142985 2022] [:notice] [pid 2528:tid 140410548673600] ModSecurity: PCRE compiled version="8.39 "; loaded version="8.39 2016-06-14"
[Thu Apr 21 23:55:35.142988 2022] [:notice] [pid 2528:tid 140410548673600] ModSecurity: LUA compiled version="Lua 5.1"
[Thu Apr 21 23:55:35.142991 2022] [:notice] [pid 2528:tid 140410548673600] ModSecurity: YAJL compiled version="2.1.0"
[Thu Apr 21 23:55:35.142994 2022] [:notice] [pid 2528:tid 140410548673600] ModSecurity: LIBXML compiled version="2.9.4"
[Thu Apr 21 23:55:35.142997 2022] [:notice] [pid 2528:tid 140410548673600] ModSecurity: Status engine is currently disabled, enable it by set SecStatusEngine to On.
[Thu Apr 21 23:55:35.187082 2022] [mpm_event:notice] [pid 2530:tid 140410548673600] AH00489: Apache/2.4.41 (Ubuntu) configured -- resuming normal operations
[Thu Apr 21 23:55:35.187125 2022] [core:notice] [pid 2530:tid 140410548673600] AH00094: Command line: '/usr/sbin/apache2'
```

{{% notice warning "Nginx with ModSecurity 2.x" "skull-crossbones" %}}

This is **not** supported. It doesn't work as expected. Our recommendation is to avoid this setup.
{{% /notice %}}

### Nginx with ModSecurity 3.x (libmodsecurity) Compiled

You can found the compilation recipe in the [ModSecurity wiki](https://github.com/SpiderLabs/ModSecurity/wiki/Compilation-recipes-for-v3.x). 

### Microsoft IIS with ModSecurity 2.x

The inital configuration file, is `modsecurity_iis.conf`. This file will be parsed by the ModSecurity for both ModSecurity and `'Include'` directives.

Additionally, in your Event Viewer, under `Windows Logs\Application'`, we should see a new log that looks like the following:

TBD: insert log image

If you have gotten to this step ModSecurity is working on IIS and you now know where to place new directives.

## Downloading OWASP CRS

Now that you know where your rules belong typically we'll want to download the OWASP CRS. The best place to get the latest copy of the ruleset will be from [our Github Releases](https://github.com/coreruleset/coreruleset/releases). There we have all our official releases listed. For production we recommend you to use the **latest release**, v{{< param crs_latest_release >}}. If you want to test the bleeding edge version, we also provide _nightly releases_.

{{% notice note %}}
Releases are signed using [our GPG key](https://coreruleset.org/security.asc), (fingerprint: 3600 6F0E 0BA1 6783 2158 8211 38EE ACA1 AB8A 6E72). You can verify the release using GPG/PGP compatible tooling.

To get our key using gpg: `gpg --keyserver pgp.mit.edu --recv 0x38EEACA1AB8A6E72` (this id should be equal to the last sixteen hex characters in our fingerprint).
You can also use `gpg --fetch-key https://coreruleset.org/security.asc` directly.
{{% /notice %}}

The steps here assume you are using a \*nix operating system. For Windows you will be doing a similar install, but probably using the zip file from our releases.

To get the release file and the corresponding signature:

```bash
wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v{{< param crs_latest_release >}}.tar.gz
wget https://github.com/coreruleset/coreruleset/releases/download/v{{< param crs_latest_release >}}/coreruleset-{{< param crs_latest_release >}}.tar.gz.asc
```

Optional verification:

```bash
gpg --verify coreruleset-{{< param crs_latest_release >}}.tar.gz.asc v{{< param crs_latest_release >}}.tar.gz
gpg: Signature made Wed Jun 30 10:05:48 2021 -03
gpg:                using RSA key 36006F0E0BA167832158821138EEACA1AB8A6E72
gpg: Good signature from "OWASP Core Rule Set <security@coreruleset.org>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 3600 6F0E 0BA1 6783 2158  8211 38EE ACA1 AB8A 6E72
```

If the signature was good, the verification succeeded. If you see a warning like the above, it means you know our public key, but you are not trusting it. You can trust it by using the following method:

```bash
gpg edit-key 36006F0E0BA167832158821138EEACA1AB8A6E72
gpg> trust
Your decision: 5 (ultimate trust)
Are you sure: Yes
gpg> quit
```

Then you will see this result when verifying:

```bash
gpg --verify coreruleset-3.3.2.tar.gz.asc v3.3.2.tar.gz
gpg: Signature made Wed Jun 30 15:05:48 2021 CEST
gpg:                using RSA key 36006F0E0BA167832158821138EEACA1AB8A6E72
gpg: Good signature from "OWASP Core Rule Set <security@coreruleset.org>" [ultimate]
```

Once you downloaded and verified the release, you are ready to continue with the setup.

### Setting up OWASP CRS

OWASP CRS contains one setup file that should be reviewed prior to completing setup. The setup file is the only configuration file within the root 'coreruleset-{{< param crs_latest_release >}}' folder and is named `csr-setup.conf.example`. Going through this configuration file and reading what the different options are is HIGHLY recommended. At minimum you should keep in mind the following.

- CRS does not configure features such as the rule engine, the audit engine, logging etc. This task is part of your initial setup. For ModSecurity, if you haven't done this yet please check out the [recommended configuration](https://github.com/SpiderLabs/ModSecurity/blob/master/modsecurity.conf-recommended)
- By default [SecDefaultAction](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-%28v2.x%29#SecDefaultAction) CRS will redirect to your local domain when an alert is triggered. This may cause redirect loops depending on your configuration. Take some time to decide what you want ModSecurity it do (drop the packet, return a status:403, go to a custom page etc.) when it detects malicious activity.
- Make sure to configure your anomaly scoring thresholds for more information see [Anomaly]({{< ref "anomaly_scoring.md" >}} "Anomaly")
- By default our rules will consider many issues with different databases and languages. If you are running in a specific environment, you probably want to limit this behavior for performance reasons.
- ModSecurity supports [Project Honeypot](https://www.projecthoneypot.org/) blacklists. This is a great project and all you need to do to leverage it is sign up for an [API key](https://www.projecthoneypot.org/httpbl_api.php) (⚠️ it might be outdated)
- Do make sure you have added any methods, static resources, content types, or file extensions that your site needs beyond the basic ones listed.

For more information please see the page on [configuration]({{< ref "crs.md" >}} "configuration"). Once you have reviewed
and configured CRS you should rename the file suffix from `.example` to `.conf`:

```bash
mv csr-setup.conf.example csr-setup.conf
```

In addition to `csr-setup.conf.example` there are two other .example files within our repository. These files are:
`rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example` and `rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example`. These files are designed to provide the rule maintainer the capability to modify rules (see [false positives and tuning]({{< ref "../configuring/false_positives_tuning.md" >}}#rule-exclusions)) without breaking forward compatibility with updates. As such you should rename these two files, removing the `.example` suffix. This will make it so that even when updates are installed they do not overwrite your custom updates. To rename the files in Linux one would use a command similar to the
following:

```bash
mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
```

## Proceeding with the Installation

The engine should support the `Include` directive out of the box. The directive tells the engine to parse additional files for directives. But where do you place this folder for it to be included? If you were to look at the CRS files, you'd note there are quite a few .conf files. While the names attempt to do a good job at describing what each file does additional information is available in the [rules](rules.md) section.

### Includes for Apache

We recommend you creating a folder specifically for the rules. In our example we have named this `modsecurity.d` and placed in within the root `<web server config>/` directory. When using Apache we can use the wildcard notation to vastly simplify our rules. Simply copying our cloned directory to our `modsecurity.d` folder and specifying the appropiate include directives will allow us to install OWASP CRS. In the example below we have also included our `modsecurity.conf` file which includes reccomended configurations for ModSecurity

```apache
<IfModule security2_module>
        Include modsecurity.d/modsecurity.conf
        Include modsecurity.d/coreruleset-{{< param crs_latest_release >}}/csr-setup.conf
        Include modsecurity.d/coreruleset-{{< param crs_latest_release >}}/rules/*.conf
</IfModule>
```

### Includes for Nginx

Nginx will include from the Nginx conf directory (`/etc/nginx` or `/usr/local/nginx/conf/` depending on the environment). Because only one `ModSecurityConfig` directive can be specified within nginx.conf we recommend naming that file `modsec_includes.conf` and including additional files from there. In the example below we copied our cloned `owasp-modsecurity-crs` folder into our Nginx configuration directory. From there we specify the appropiate include directives which will include OWASP CRS when the server is restarted. In the example below we have also included our `modsecurity.conf` file which includes reccomended configurations for ModSecurity

```nginx
include modsecurity.conf
include coreruleset-{{< param crs_latest_release >}}/crs-setup.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-901-INITIALIZATION.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-903.9001-DRUPAL-EXCLUSION-RULES.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-903.9003-NEXTCLOUD-EXCLUSION-RULES.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-903.9004-DOKUWIKI-EXCLUSION-RULES.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-903.9005-CPANEL-EXCLUSION-RULES.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-903.9006-XENFORO-EXCLUSION-RULES.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-905-COMMON-EXCEPTIONS.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-910-IP-REPUTATION.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-911-METHOD-ENFORCEMENT.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-912-DOS-PROTECTION.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-913-SCANNER-DETECTION.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-921-PROTOCOL-ATTACK.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-934-APPLICATION-ATTACK-NODEJS.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-944-APPLICATION-ATTACK-JAVA.conf
include coreruleset-{{< param crs_latest_release >}}/rules/REQUEST-949-BLOCKING-EVALUATION.conf
include coreruleset-{{< param crs_latest_release >}}/rules/RESPONSE-950-DATA-LEAKAGES.conf
include coreruleset-{{< param crs_latest_release >}}/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf
include coreruleset-{{< param crs_latest_release >}}/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf
include coreruleset-{{< param crs_latest_release >}}/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf
include coreruleset-{{< param crs_latest_release >}}/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf
include coreruleset-{{< param crs_latest_release >}}/rules/RESPONSE-959-BLOCKING-EVALUATION.conf
include coreruleset-{{< param crs_latest_release >}}/rules/RESPONSE-980-CORRELATION.conf
include coreruleset-{{< param crs_latest_release >}}/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
``` 
