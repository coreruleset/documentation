---
title: Extended Install
weight: 30
disableToc: false
chapter: false
---

> All the information needed to properly install CRS is presented on this page. The installation concepts are expanded upon and presented in more detail than the [quick start guide]({{% ref "install.md" %}}).

## Contact Us

To contact the CRS project with questions or problems, reach out via the project's [Google group](https://groups.google.com/a/owasp.org/forum/#!forum/modsecurity-core-rule-set-project) or [Slack channel](https://owasp.slack.com/archives/CBKGH8A5P) (for Slack channel access, [use this link](https://owasp.org/slack/invite) to get an invite).

## Prerequisites

Installing the CRS isn't very difficult but does have one major requirement: *a compatible engine*. The reference engine used throughout this page is ModSecurity.

{{% notice note %}}
In order to successfully run CRS `3.x` using ModSecurity it is recommended to use the latest version available. For Nginx use the `3.x` branch of ModSecurity, and for Apache use the latest `2.x` branch.
{{% /notice %}}

## Installing a Compatible WAF Engine

Two different methods to get an engine up and running are presented here:

- using the chosen engine as provided and packaged by the OS distribution
- compiling the chosen engine from source

A ModSecurity installation is presented in the examples below, however the install documentation for the Coraza engine can be found [here](https://www.coraza.io).

### Option 1: Installing Pre-Packaged ModSecurity

ModSecurity is frequently pre-packaged and is available from several major Linux distributions.

- **Debian:** Friends of the CRS project [DigitalWave](https://modsecurity.digitalwave.hu) package and, most importantly, **keep ModSecurity updated** for Debian and derivatives.
- **Fedora:** Execute `dnf install mod_security` for Apache + ModSecurity v2.
- **RHEL compatible:** Install EPEL and then execute `yum install mod_security`.

For Windows, get the latest MSI package from https://github.com/owasp-modsecurity/ModSecurity/releases.

{{% notice warning %}}
**Distributions might not update their ModSecurity releases frequently.** 

As a result, it is quite likely that a distribution's version of ModSecurity may be missing important features or **may even contain security vulnerabilities**. Additionally, depending on the package and package manager used, the ModSecurity configuration will be laid out slightly differently.
{{% /notice %}}

As the different engines and distributions have different layouts for their configuration, to simplify the documentation presented here the prefix `<web server config>/` will be used from this point on.

Examples of `<web server config>/` include:

- `/etc/apache2` in Debian and derivatives
- `/etc/httpd` in RHEL and derivatives
- `/usr/local/apache2` if Apache was compiled from source using the default prefix
- `C:\Program Files\ModSecurity IIS\` (or Program Files(x86), depending on configuration) on Windows
- `/etc/nginx`

### Option 2: Compiling ModSecurity From Source

Compiling ModSecurity is easy, but slightly outside the scope of this document. For information on how to compile ModSecurity, refer to:

- the official [ModSecurity documentation](https://github.com/owasp-modsecurity/ModSecurity/wiki) on GitHub
- the compilation recipes for ModSecurity v3 on the [ModSecurity wiki](https://github.com/owasp-modsecurity/ModSecurity/wiki/Compilation-recipes-for-v3.x)
- the netnea tutorials for [Apache](https://www.netnea.com/cms/apache-tutorial-6_embedding-modsecurity/) or [Nginx](https://www.netnea.com/cms/nginx-tutorial-6_embedding-modsecurity/)

{{% notice warning "Unsupported Configurations" "skull-crossbones" %}}
Note that the following configurations are **not** supported. They do **not** work as expected. The CRS project recommendation is to *avoid these setups*:

- Nginx with ModSecurity v2
- Apache with ModSecurity v3
{{% /notice %}}

#### Testing the Compiled Module

Once ModSecurity has been compiled, there is a simple test to see if the installation is working as expected. After compiling from source, use the appropriate directive to **load the newly compiled module** into the web server. For example:

- **Apache:** `LoadModule security2_module modules/mod_security2.so`
- **Nginx:** `load_module modules/ngx_http_modsecurity_module.so;`

Now restart the web server. ModSecurity should output that it's being used.

Nginx should show something like:

```
2022/04/21 23:45:52 [notice] 1#1: ModSecurity-nginx v1.0.2 (rules loaded inline/local/remote: 0/6/0)
```

Apache should show something like:

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

##### Microsoft IIS with ModSecurity 2.x

The initial configuration file is `modsecurity_iis.conf`. This file will be parsed by ModSecurity for both ModSecurity directives and `'Include'` directives.

Additionally, in the Event Viewer, under `Windows Logs\Application`, it should be possible to see a new log entry showing ModSecurity being successfully loaded.

At this stage, the ModSecurity on IIS setup is working and new directives can be placed in the configuration file as needed.

## Downloading OWASP CRS

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
gpg: Good signature from "OWASP CRS <security@coreruleset.org>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 3600 6F0E 0BA1 6783 2158  8211 38EE ACA1 AB8A 6E72
```

If the signature was good then the verification succeeds. If a warning is displayed, like the above, it means the CRS project's public key is *known* but is not *trusted*.

To trust the CRS project's public key:

```bash
gpg --edit-key 36006F0E0BA167832158821138EEACA1AB8A6E72
gpg> trust
Your decision: 5 (ultimate trust)
Are you sure: Yes
gpg> quit
```

The result when verifying a release will then look like so:

```bash
gpg --verify coreruleset-{{< param crs_latest_release >}}.tar.gz.asc v{{< param crs_latest_release >}}.tar.gz
gpg: Signature made Wed Jun 30 15:05:48 2021 CEST
gpg:                using RSA key 36006F0E0BA167832158821138EEACA1AB8A6E72
gpg: Good signature from "OWASP CRS <security@coreruleset.org>" [ultimate]
```

With the CRS release downloaded and verified, the rest of the set up can continue.

## Setting Up OWASP CRS

OWASP CRS contains a setup file that should be reviewed prior to completing set up. The setup file is the only configuration file within the root 'coreruleset-{{< param crs_latest_release >}}' folder and is named `crs-setup.conf.example`. Examining this configuration file and reading what the different options are is **highly** recommended.

At a minimum, keep in mind the following:

- CRS does not configure features such as the rule engine, audit engine, logging, etc. This task is part of the initial *engine* setup and is not a job for the rule set. For ModSecurity, if not already done, see the [recommended configuration](https://github.com/owasp-modsecurity/ModSecurity/blob/master/modsecurity.conf-recommended).
- Decide what ModSecurity should do when it detects malicious activity, e.g., drop the packet, return a *403 Forbidden* status code, issue a redirect to a custom page, etc.
- Make sure to configure the anomaly scoring thresholds. For more information see [Anomaly]({{% ref "anomaly_scoring.md" %}} "Anomaly").
- By default, the CRS rules will consider many issues with different databases and languages. If running in a specific environment, e.g., without any SQL database services present, it is probably a good idea to limit this behavior for performance reasons.
- Make sure to add any HTTP methods, static resources, content types, or file extensions that are needed, beyond the default ones listed.

Once reviewed and configured, the CRS configuration file should be renamed by changing the file suffix from `.example` to `.conf`:

```bash
mv crs-setup.conf.example crs-setup.conf
```

In addition to `crs-setup.conf.example`, there are two other ".example" files within the CRS repository. These are:

- `rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example`
- `rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example`

These files are designed to provide the rule maintainer with the ability to modify rules (see [false positives and tuning]({{% ref "#rule-exclusions" %}})) without breaking forward compatibility with rule set updates. These two files should be renamed by removing the `.example` suffix. This will mean that installing updates will *not* overwrite custom rule exclusions. To rename the files in Linux, use a command similar to the following:

```bash
mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
```

## Proceeding with the Installation

The engine should support the `Include` directive out of the box. This directive tells the engine to parse *additional* files for directives. The question is where to put the CRS rules folder in order for it to be included.

Looking at the CRS files, there are quite a few ".conf" files. While the names attempt to do a good job at describing what each file does, additional information is available in the [rules]({{% ref "rules" %}}) section.

### Includes for Apache

It is recommended to create a folder specifically to contain the CRS rules. In the example presented here, a folder named `modsecurity.d` has been created and placed within the root `<web server config>/` directory. When using Apache, wildcard notation can be used to vastly simplify the `Include` rules. Simply copying the cloned directory into the `modsecurity.d` folder and specifying the appropriate `Include` directives will install OWASP CRS. In the example below, the `modsecurity.conf` file has also been included, which includes recommended configurations for ModSecurity.

```apache
<IfModule security2_module>
  Include modsecurity.d/modsecurity.conf
  Include {{< param crs_install_dir >}}/crs-setup.conf
  Include {{< param crs_install_dir >}}/plugins/*-config.conf
  Include {{< param crs_install_dir >}}/plugins/*-before.conf
  Include {{< param crs_install_dir >}}/rules/*.conf
  Include {{< param crs_install_dir >}}/plugins/*-after.conf
</IfModule>
```

### Includes for Nginx

Nginx will include files from the Nginx configuration directory (`/etc/nginx` or `/usr/local/nginx/conf/`, depending on the environment). Because only one `ModSecurityConfig` directive can be specified within `nginx.conf`, it is recommended to name that file `modsec_includes.conf` and include additional files from there. In the example below, the cloned `coreruleset` folder was copied into the Nginx configuration directory. From there, the appropriate include directives are specified which will include OWASP CRS when the server is restarted. In the example below, the `modsecurity.conf` file has also been included, which includes recommended configurations for ModSecurity.

```nginx
  Include modsecurity.d/modsecurity.conf
  Include {{< param crs_install_dir >}}/crs-setup.conf
  Include {{< param crs_install_dir >}}/plugins/*-config.conf
  Include {{< param crs_install_dir >}}/plugins/*-before.conf
  Include {{< param crs_install_dir >}}/rules/*.conf
  Include {{< param crs_install_dir >}}/plugins/*-after.conf
```

{{% notice note %}}
You will also need to include the plugins you want along with your CRS installation.
{{% /notice %}}
