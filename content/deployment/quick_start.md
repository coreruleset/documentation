---
title: "Quick Start Guide"
chapter: false
weight: 10
---

Welcome to the OWASP Core RuleSet (CRS) quick start guide. We will
attempt to get you up and running with CRS as quick as possible. This
guide assumes ModSecurity is already working. If you are unsure see the
[extended install]({{< ref "install.md" >}}) page. Otherwise, lets jump in.

You'll first need to download the ruleset. Our strong recommendation is that you [use a supported version](https://github.com/coreruleset/coreruleset/security/policy). Using a browser (or
equivalent) visit the following URL: https://github.com/coreruleset/coreruleset/releases.

There we have all our official releases listed. For production we recommend you to use the latest release, v{{< param crs_latest_release >}}. If you want to test the bleeding edge version, we also provide _nightly releases_.

### Verifying our release

{{% notice note %}}
Releases are signed using [our GPG key](https://coreruleset.org/security.asc), (fingerprint: 3600 6F0E 0BA1 6783 2158 8211 38EE ACA1 AB8A 6E72). You can verify the release using GPG/PGP compatible tooling.

To get our key using gpg from public servers: `gpg --keyserver pgp.mit.edu --recv 0x38EEACA1AB8A6E72` (this id should be equal to the last sixteen hex characters in our fingerprint).
You can also use `gpg --fetch-key https://coreruleset.org/security.asc` directly.
{{% /notice %}}

The steps here assume you are using a *nix operating system. For Windows you will be doing a similar install, but probably using the zip file from our releases.

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

### Installing the files

Once you downloaded and verified the release, extract it somewhere well known on your server.
Typically this will be in the webserver directory. We are demonstrating
with Apache below. For information on configuring Nginx or IIS see
the [extended install]({{< ref "install.md" >}}) page. Additionally, while it is a
successful practice to make a new `modsecurity.d` folder as outlined
below, it isn't strictly necessary. The path scheme outlined is the
common to RHEL based operating systems, you may have to adjust the
Apache path used to match your installation.

```bash
mkdir /etc/httpd/modsecurity.d
tar -zxvf v{{< param crs_latest_release >}}.tar.gz -C /etc/httpd/modsecurity.d/owasp-modsecurity-crs
```

After extracting the rule set we have to set up the main OWASP Core Rule Set
configuration file. We provide an example configuration file as part of
the package located in the main directory: `csr-setup.conf.example`.

(Note: Other aspects of ModSecurity are controlled by the
recommended ModSecurity configuration rules, packaged with ModSecurity)

For many people
this will be a good enough starting point but you should take the time
to look through this file before deploying it to make sure it's right
for your environment. For more information see [configuration]({{< ref "../configuring/crs.md" >}}).

Once you have changed any settings within the configuration file, as
needed, you should rename it to remove the .example portion

```bash
cd /etc/httpd/modsecurity.d/owasp-modsecurity-crs/
mv csr-setup.conf.example csr-setup.conf
```

Only one more step! We now have to tell our web server where our rules
are. We do this by including the rule configuration files in our
httpd.conf file. Again, we are demonstrating using Apache but it is
similar on other systems see the [extended install]({{< ref "install.md" >}}) page for details.

```bash
echo 'IncludeOptional /etc/httpd/owasp-modsecurity-crs/csr-setup.conf' >> /etc/httpd/conf/httpd.conf
echo 'IncludeOptional /etc/httpd/owasp-modsecurity-crs/rules/*.conf' >> /etc/httpd/conf/httpd.conf
```

Now that we have configured everything you should be able to restart and
enjoy using the OWASP Core Rule Set. Typically these rules will require
a bit of exception tuning, depending on your site. For more information
see [false positives and tuning]({{< ref "false_positives_tuning.md" >}}). Enjoy!

```bash
systemctl restart httpd.service
```

## Using Containers

Another quick option is to leverage our pre-packaged containers. You can use docker, podman, or any container compatible engine. Our images are published in the docker hub. The one you probably want is the `owasp/modsecurity-crs`: it already has everything to get you up and running quickly.

We already pre-package both Apache and Nginx Web servers with the corresponding ModSecurity engine. More engines (like Coraza) will come later.

So to protect your running Web Server, just get the image and use these configuration variables to make the WAF receive the requests and proxy your server.

This is an example `docker-compose` that can be used to pull the container images. You just need to change the `BACKEND` server so it points to your own server:

```docker-compose
services:
  modsec2-apache:
    container_name: modsec2-apache
    image: owasp/modsecurity-crs:apache
    environment:
      SERVERNAME: modsec2-apache
      BACKEND: http://<your own server>
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

That's it! Now just starting that container will give you the latest stable CRS protecting your site. There are [plenty of additional variables](https://github.com/coreruleset/modsecurity-crs-docker) you can use to configure the container image and its behavior. Be sure to check those out!
