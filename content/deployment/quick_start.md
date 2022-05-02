---
title: "Quick Start Guide"
chapter: false
weight: 10
---

> This quick start guide aims to get a CRS installation up and running as quickly as possible. This guide assumes that ModSecurity is already present and working. If unsure then refer to the [extended install]({{< ref "install.md" >}}) page for full details.

## Downloading the Rule Set

The first step is to download the Core Rule Set itself. The CRS project strongly recommends using a [supported version](https://github.com/coreruleset/coreruleset/security/policy).

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

In many scenarios, the default example CRS configuration will be a good enough starting point. It is, however, a good idea to take the time to look through the example configuration file *before* deploying it to make sure it's right for a given environment. For more information see [configuration]({{< ref "../concepts/crs.md" >}}).

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

## Alternative: Using Containers

Another quick option is to use the official CRS [pre-packaged containers]({{< ref "../development/useful_tools/#official-crs-maintained-docker-images" >}}). Docker, Podman, or any compatible container engine can be used. The official CRS images are published in the Docker Hub. The image most often deployed is `owasp/modsecurity-crs`: it already has everything needed to get up and running quickly.

The CRS project pre-packages both Apache and Nginx web servers along with the appropriate corresponding ModSecurity engine. More engines, like [Coraza](https://coraza.io/), will be added at a later date.

To protect a running web server, all that's required is to get the appropriate image and set its configuration variables to make the WAF receives requests and proxies them to your backend server.

Below is an example `docker-compose` file that can be used to pull the container images. All that needs to be changed is the `BACKEND` variable so that the WAF points to the backend server in question:

```docker-compose
services:
  modsec2-apache:
    container_name: modsec2-apache
    image: owasp/modsecurity-crs:apache
    environment:
      SERVERNAME: modsec2-apache
      BACKEND: http://<backend server>
      PORT: "80"
      MODSEC_RULE_ENGINE: DetectionOnly
      BLOCKING_PARANOIA: 2
      TZ: "${TZ}"
      ERRORLOG: "/var/log/error.log"
      ACCESSLOG: "/var/log/access.log"
      MODSEC_AUDIT_LOG_FORMAT: Native
      MODSEC_AUDIT_LOG_TYPE: Serial
      MODSEC_AUDIT_LOG: "/var/log/modsec_audit.log"
      MODSEC_TMP_DIR: "/tmp"
      MODSEC_RESP_BODY_ACCESS: "On"
      MODSEC_RESP_BODY_MIMETYPE: "text/plain text/html text/xml application/json"
      COMBINED_FILE_SIZES: "65535"
    volumes:
    ports:
      - "80:80"
```

That's all that needs to be done. Simply starting the container described above will instantly provide the protection of the latest stable CRS release in front of a given backend server or service. There are [lots of additional variables](https://github.com/coreruleset/modsecurity-crs-docker) that can be used to configure the container image and its behavior, so be sure to read the full documentation.

## Verifying that the CRS is active

Always verify that CRS is installed correctly by sending a 'malicious' request to your site or application, for instance:

```bash
curl 'https://www.example.com/?foo=/etc/passwd&bar=/bin/sh'
```

Depending on your configurated thresholds, this should be detected as a malicious request. If you use blocking mode, you should receive an Error 403. The request should also be logged to the audit log, which is usually in `/var/log/modsec_audit.log`.
