---
title: "Installing CoreRuleSet"
menuTitle: "Extended Install"
chapter: false
disableToc: false
weight: 20
---

#### TODO: insert TOC

If you need mode information than the one in the [quickstart guide]({{< ref "quickstart.md" >}}), here we extend with additional details so keep reading.

Below you should find all the information you need to properly install CRS. If you are having problems feel free to reach out to our [Google Group](https://groups.google.com/a/owasp.org/forum/#!forum/modsecurity-core-rule-set-project), or our [Slack Channel](https://owasp.slack.com/archives/CBKGH8A5P). If you don't have access yet, [get your invite here](https://owasp.org/slack/invite).

## Prerequisites

Installing the CRS isn't very hard but it does have one major requirement: a compatible engine. The base reference engine shown here is ModSecurity.

{{% notice warning %}}
In order to run the CRS `3.x` using ModSecurity we recommend you to use the latest version available. For Nginx please use the `3.x` branch of ModSecurity, and for Apache use the latest `2.x` branch.
{{% /notice %}}

## How to install a compatible engine

Here we will cover two different ways of getting your engine up and running: you can use your favorite engine provided by your OS distribution, or it can be compiled from source. Here we will cover ModSecurity installs, but you can see the Coraza install documents [here](https://www.coraza.io).

### Installing ModSecurity in your Linux distribution

Pre-packaged modsecurity can be get from major distributions.

- Debian: our friends at [DigitalWave](https://modsecurity.digitalwave.hu) package and keep updates of ModSecurity for debian and derivatives
- Fedora: 
  - `dnf install mod_security` for Apache + ModSecurity2
  - `dnf install libmodse
- RHEL compatible: you will need to install epel and then `yum install mod_security`.

### Compiling ModSecurity

Compiling ModSecurity is easy, but slightly outside the scope of this document. If you are interested in learning how to compile ModSecurity please go to the ModSecurity documentation. Having compiled ModSecurity there is a simple test to see if your installation is working. If you have compiled from source you would have needed to include `LoadModule security2_module modules/mod_security2.so` either in `httpd.conf` (`apache2.conf` on Debian) or in some file included from this file. Anywhere after you load your module you may add the following ModSecurity directives.

```apache
SecRuleEngine On
SecRule ARGS:testparam "@contains test" "id:1234,deny,status:403,msg:'Our test rule has triggered'"
```

If you restart Apache you may now navigate to any page on your web server passing the parameter `'testparam'` with the value `'test'` (via post or get) and you should receive a 403. This request will typically appear similar to as follows: `http://localhost/?testparam=test`.

If you obtained a 403 status code your ModSecurity instance is functioning correctly with Apache and you now know where to place directives.

### Apache 2.x with ModSecurity 2.x Packaged (RHEL)

Many operating systems provide package managers in order to aid in the install of software packages and their associated dependencies. Even though ModSecurity is relatively straight forward to install, some people prefer using package managers due to their ease. It should be noted here that many package managers do not up date their releases very frequently, as a result it is quite likely that your distribution may be missing required features or possibly even have security vulnerabilities. Additionally, depending on your package/package manager your ModSecurity configuration will be laid out slightly different.

On Fedora we will find that when you use `dnf install mod_security` you will receive the base ModSecurity package. Apache's configuration files are split out within this environment such that there are different folders for the base config (`/etc/httpd/config`), user configuration (`/etc/httpd/conf.d`, and module configuration (`/etc/httpd/conf.modules.d/`). The Fedora ModSecurity 2.x package places the LoadModule and associated 'Include's within `/etc/httpd/conf.modules.d/10-mod_security.conf`. Additionally, it places some of the reccomended default rules in `/etc/httpd/conf.d/mod_security.conf`. It is this secondary configuration file that will setup the locations where you should add your rules. By default it reads in all config files from the `/etc/httpd/modsecurity.d/` and `/etc/httpd/modsecurity.d/activated_rules/` folder. To keep order I would reccomend testing this configuration by placing a `rules.conf` file within the `activated_rules` folder. Within this `rules.conf` file add the following:

```bash
SecRuleEngine On
SecRule ARGS:testparam "@contains test" "id:1234,deny,status:403,msg:'Our test rule has triggered'"
```

Upon saving and restarting Apache (`systemctl restart httpd.service`) you should be able to navigate to a your local webserver. Once this is accomplished try passing the 'testparam' paramater with the value 'test' such as via the following
URL: `http://localhost/?testparam=test`. You should receive a 403 Forbidden status. If you do congratulations, ModSecurity is ready for the OWASP CRS rules.

{{% notice error %}}
**Nginx with ModSecurity 2.x**

This is not supported. It doesn't work as expected.
{{% /notice %}}

### Nginx with ModSecurity 3.x (libmodsecurity) Compiled

TBD

### Microsoft IIS with ModSecurity 2.x

The most common deployment of ModSecurity for IIS is via the pre-packaged MSI installer, available at <https://www.modsecurity.org/download.html>. If you compiled or are looking to compile ModSecurity for IIS this documentation isn't for
you.
 If you used this package to install ModSecurity 2.x on IIS (tested on IIS 7-10), than your configuration files are located within`C:\Program Files\ModSecurity IIS\` (or Program Files(x86) depending on your configuration). The inital configuration file, that is the one that the remainder are included from, is `modsecurity_iis.conf`. This file will be parsed by the ModSecurity for both ModSecurity and `'Include'` directives.

By default all installations of ModSecurity without [SecRuleEngine](<https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleEngine>) declared will start in DetectionOnly mode. IIS, by default, explicitly declares [SecRuleEngine](<https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleEngine>) to be DetectionOnly within the included modsecurity.conf file. As a result any rule we make will only show up in the Windows Event Viewer by default. For our example we're going to turn on disruptive actions. To test we should add the following to the end of our `modsecurity_iis.conf`:

```apache
SecRuleEngine On
SecRule ARGS:testparam "@contains test" "id:1234,deny,status:403,msg:'Our test rule has triggered'"
```

This rule will be triggered when you go to your web page and pass the testparam (via either GET or POST) with the test value. This typically will looks similar to the following: `http://localhost/?testparam=test`.

If all went well you should see an HTTP 403 Forbidden in your browser when you navigate to the site in question. Additionally, in your Event Viewer, under 'Windows Logs'-\>'Application', we should see a new log that looks like the following:

TBD: insert log image

If you have gotten to this step ModSecurity is functioning on IIS and you now know where to place new directives.

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

OWASP CRS contains one setup file that should be reviewed prior to
completing setup. The setup file is the only configuration file within
the root 'coreruleset-{{< param crs_latest_release >}}' folder and is named
`csr-setup.conf.example`. Going through this configuration file
and reading what the different options are is
HIGHLY recommended. At minimum you should keep in mind the following.

- CRS does not configure ModSecurity features such as the rule engine,
  the audit engine, logging etc. This task is part of the ModSecurity
  initial setup.If you haven't done this yet please check out the
  [recommended ModSecurity configuration](https://github.com/SpiderLabs/ModSecurity/blob/master/modsecurity.conf-recommended)
- By default [SecDefaultAction](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-%28v2.x%29#SecDefaultAction) CRS will redirect to your local domain when an alert is triggered.
  This may cause redirect loops depending on your configuration. Take
  some time to decide what you want ModSecurity it do (drop the
  packet, return a status:403, go to a custom page etc.) when it
  detects malicious activity.
- Make sure to configure your anomaly scoring thresholds for more
  information see [Anomaly]({{< ref "anomaly_scoring.md" >}} "Anomaly")
- By default ModSecurity looks for lots of issues with different
  databases and languages, if you are running a specific environment,
  you probably want to limit this behavior for performance reasons.
- ModSecurity supports [Project Honeypot](https://www.projecthoneypot.org/) blacklists. This is a
  great project and all you need to do to leverage it is sign up for
  an [API key](https://www.projecthoneypot.org/httpbl_api.php) (⚠️ it might be outdated)
- Do make sure you have added any methods, static resources, content
  types, or file extensions that your site needs beyond the basic ones
  listed.

For more information please see the page on
[configuration]({{< ref "crs.md" >}} "configuration"). Once you have reviewed
and configured CRS you should rename the file suffix from `.example` to
`.conf`:

```bash
mv csr-setup.conf.example csr-setup.conf
```

In addition to `csr-setup.conf.example` there are two other .example files
within our repository. These files are:
`rules/REQUEST-00-LOCAL-WHITELIST.conf.example` and
`rules/RESPONSE-99-EXCEPTIONS.conf.example`. These files are designed to
provide the rule maintainer the capability to modify rules (see
[false positives and tuning]({{< ref "../configuring/false_positives_tuning.md" >}}#rule-exclusions)) without breaking forward
compatability with updates. As such you should rename these two files,
removing the `.example` suffix. This will make it so that even when
updates are installed they do not overwrite your custom updates. To
rename the files in Linux one would use a command similar to the
following:

```bash
mv rules/REQUEST-00-LOCAL-WHITELIST.conf.example rules/REQUEST-00-LOCAL-WHITELIST.conf
mv rules/RESPONSE-99-EXCEPTIONS.conf.example rules/RESPONSE-99-EXCEPTIONS.conf
```

## Proceeding with the Installation

Both ModSecurity 2.x (via APR) and ModSecurity 3.x support the Include
directive and what it tells the ModSecurity core to do is parse the
additional files for ModSecurity directives. But where do you place this
folder for it to be included? If you were to look at the CRS files,
you'd note there are quite a few .conf files. While the names attempt
to do a good job at describing what each file does additional
information is available in the [rules](rules.md)
section.

## Finding where to edit in your configuration

ModSecurity comes in MANY different version with support for a multitude
of Operating Systems (OS) and Web Servers. The installation locations
may differ greatly between these different options so please be aware
that the following are just some of the more common configurations.

### Includes for Apache

Apache will include from the Apache Root directory (`/etc/httpd/`,
`/etc/apache2/`, or `/usr/local/apache2/` depending on the envirovment).
Typically we reccomend following the Fedora practice of creating a
folder specificlly for ModSecurity rules. In our example we have named
this modsecurity.d and placed in within the root Apache directory. When
using Apache we can use the wildcard notation to vastly simplify our
rules. Simply copying our cloned directory to our modsecurity.d folder
and specifying the appropertie include directives will allow us to
install OWASP CRS. In the example below we have also included our
`modsecurity.conf` file which includes reccomended configurations for
ModSecurity

```apache
<IfModule security2_module>
        Include modsecurity.d/modsecurity.conf
        Include modsecurity.d/owasp-modsecurity-crs/csr-setup.conf
        Include modsecurity.d/owsp-modsecurity-crs/rules/*.conf
</IfModule>
```

### Includes for Nginx

Nginx will include from the Nginx conf directory (`/usr/local/nginx/conf/`
depending on the envirovment). Because only one `ModSecurityConfig`
directive can be specified within nginx.conf we reccomend naming that
file `modsec_includes.conf` and including additional files from there. In
the example below we copied our cloned `owasp-modsecurity-crs` folder into
our Nginx configuration directory. From there we specifying the
appropertie include directives which will include OWASP CRS when the
server is restarted. In the example below we have also included our
`modsecurity.conf` file which includes reccomended configurations for
ModSecurity

```nginx
include modsecurity.conf
include owasp-modsecurity-crs/csr-setup.conf
include owasp-modsecurity-crs/rules/REQUEST-00-LOCAL-WHITELIST.conf
include owasp-modsecurity-crs/rules/REQUEST-01-COMMON-EXCEPTIONS.conf
include owasp-modsecurity-crs/rules/REQUEST-10-IP-REPUTATION.conf
include owasp-modsecurity-crs/rules/REQUEST-11-METHOD-ENFORCEMENT.conf
include owasp-modsecurity-crs/rules/REQUEST-12-DOS-PROTECTION.conf
include owasp-modsecurity-crs/rules/REQUEST-13-SCANNER-DETECTION.conf
include owasp-modsecurity-crs/rules/REQUEST-20-PROTOCOL-ENFORCEMENT.conf
include owasp-modsecurity-crs/rules/REQUEST-21-PROTOCOL-ATTACK.conf
include owasp-modsecurity-crs/rules/REQUEST-30-APPLICATION-ATTACK-LFI.conf
include owasp-modsecurity-crs/rules/REQUEST-31-APPLICATION-ATTACK-RFI.conf
include owasp-modsecurity-crs/rules/REQUEST-32-APPLICATION-ATTACK-RCE.conf
include owasp-modsecurity-crs/rules/REQUEST-33-APPLICATION-ATTACK-PHP.conf
include owasp-modsecurity-crs/rules/REQUEST-41-APPLICATION-ATTACK-XSS.conf
include owasp-modsecurity-crs/rules/REQUEST-42-APPLICATION-ATTACK-SQLI.conf
include owasp-modsecurity-crs/rules/REQUEST-43-APPLICATION-ATTACK-SESSION-FIXATION.conf
include owasp-modsecurity-crs/rules/REQUEST-49-BLOCKING-EVALUATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-50-DATA-LEAKAGES-IIS.conf
include owasp-modsecurity-crs/rules/RESPONSE-50-DATA-LEAKAGES-JAVA.conf
include owasp-modsecurity-crs/rules/RESPONSE-50-DATA-LEAKAGES-PHP.conf
include owasp-modsecurity-crs/rules/RESPONSE-50-DATA-LEAKAGES.conf
include owasp-modsecurity-crs/rules/RESPONSE-51-DATA-LEAKAGES-SQL.conf
include owasp-modsecurity-crs/rules/RESPONSE-59-BLOCKING-EVALUATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-80-CORRELATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-99-EXCEPTIONS.conf
```

## Setting up automated updates

todo: The OWASP Core Rule Set is designed with the capability to be
frequently updated in mind. New threats and techniques and updates are
provided frequently as part of the rule set and as a result, in order to
combat the latest threats effectivly it is imperative that constant
updates should be part of your strategy.
