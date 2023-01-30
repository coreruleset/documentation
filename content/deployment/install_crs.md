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
