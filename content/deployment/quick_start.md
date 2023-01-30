---
title: Quick Start Guide
weight: 20
disableToc: false
chapter: false
---

> This quick start guide aims to get a CRS installation up and running as quickly as possible. This guide assumes that ModSecurity is already present and working. If unsure then refer to the [extended install]({{< ref "install.md" >}}) page for full details.

## Installing the Rule Set

### Extracting the Files

Once the rule set has been downloaded and verified, extract the rule set files to a well known location on the server. This will typically be somewhere in the web server directory.

The examples presented below demonstrate using Apache. For information on configuring Nginx or IIS see the [extended install]({{< ref "install.md" >}}) page.

Note that while it's common practice to make a new `modsecurity.d` folder, as outlined below, this isn't strictly necessary. The path scheme outlined is common on RHEL-based operating systems; the Apache path used may need to be adjusted to match the server's installation.

```bash
mkdir /etc/httpd/modsecurity.d
tar -zxvf v{{< param crs_latest_release >}}.tar.gz -C /etc/httpd/modsecurity.d/owasp-modsecurity-crs
```

### Setting Up the Main Configuration File

After extracting the rule set files, the next step is to set up the main OWASP Core Rule Set configuration file. An example configuration file is provided as part of the release package, located in the main directory: `crs-setup.conf.example`.

{{% notice note %}}
Other aspects of ModSecurity, particularly engine-specific parameters, are controlled by the ModSecurity "recommended" configuration rules, `modsecurity.conf-recommended`. This file comes packaged with ModSecurity itself.
{{% /notice %}}

In many scenarios, the default example CRS configuration will be a good enough starting point. It is, however, a good idea to take the time to look through the example configuration file *before* deploying it to make sure it's right for a given environment.

Once any settings have been changed within the example configuration file, as needed, it should be renamed to remove the .example portion, like so:

```bash
cd /etc/httpd/modsecurity.d/owasp-modsecurity-crs/
mv crs-setup.conf.example crs-setup.conf
```

### Include-ing the Rule Files

The last step is to tell the web server where the rules are. This is achieved by `include`-ing the rule configuration files in the `httpd.conf` file. Again, this example demonstrates using Apache, but the process is similar on other systems (see the [extended install]({{< ref "install.md" >}}) page for details).

```bash
echo 'IncludeOptional /etc/httpd/owasp-modsecurity-crs/crs-setup.conf' >> /etc/httpd/conf/httpd.conf
echo 'IncludeOptional /etc/httpd/owasp-modsecurity-crs/rules/*.conf' >> /etc/httpd/conf/httpd.conf
```

Now that everything has been configured, it should be possible to restart and being using the OWASP Core Rule Set. The CRS rules typically require a bit of tuning with rule exclusions, depending on the site and web applications in question. For more information on tuning, see [false positives and tuning]({{< ref "false_positives_tuning.md" >}}).

```bash
systemctl restart httpd.service
```
