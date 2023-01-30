---
title: "Installing a Compatible Engine"
weight: 15
disableToc: false
chapter: false
---

> TODO

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

For Windows, get the latest MSI package from https://github.com/SpiderLabs/ModSecurity/releases.

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

- the official [ModSecurity documentation](https://github.com/SpiderLabs/ModSecurity/wiki) on GitHub
- the compilation recipes for ModSecurity v3 on the [ModSecurity wiki](https://github.com/SpiderLabs/ModSecurity/wiki/Compilation-recipes-for-v3.x)
- the netnea tutorials for [Apache](https://www.netnea.com/cms/apache-tutorial-6_embedding-modsecurity/) or [Nginx](https://www.netnea.com/cms/nginx-tutorial-6_embedding-modsecurity/)
