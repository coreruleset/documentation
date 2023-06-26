---
title: "Installing a Compatible Engine"
weight: 15
disableToc: false
chapter: false
---

> The first step to a fully functional CRS installation is to have a compatible *engine* in place. The engine provides the tools and functionality to parse and inspect web traffic. This page walks through some common options.

## Option 1: Use a Container

A quick and simple option is to use the official CRS [pre-packaged Docker container]({{< ref "../development/useful_tools/#official-crs-maintained-docker-images" >}} "Page detailing the official CRS maintained Docker image."), which avoids the need to install an engine by hand. This official CRS image is published on Docker Hub and provides both a pre-built engine in addition to the Core Rule Set itself.

The image can be found at `owasp/modsecurity-crs` and has everything needed to get up and running quickly. Docker, Podman, or any similar, compatible container engine can be used.

The CRS project pre-packages both Apache and Nginx web servers along with the appropriate corresponding ModSecurity engine. More engines, like [Coraza](https://coraza.io/), will be added at a later date.

Protecting an existing web server is simple. First get the appropriate CRS container image and then set its configuration variables so that the WAF container acts as a reverse proxy, receiving inbound requests and proxying them to the web server.

Presented below is an example `docker-compose` configuration that can be used to pull the required container image. All that needs to be changed is the `BACKEND` variable to make the WAF point to the backend web server in question:

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

That's all that needs to be done. Simply starting the container described in the configuration above will provide the protection of the latest stable CRS release in front of a given backend server or service. [Many additional variables](https://github.com/coreruleset/modsecurity-crs-docker "Link to the full CRS Docker documentation on GitHub.") can be used to configure the container image and its behavior, so it is recommended to read the full documentation for best results.

## Option 2: Install a Compatible Engine

The most flexible option is to install (and optionally also compile) a compatible engine to run CRS on. At the present time, the main engine options available are ModSecurity v2, ModSecurity v3, and Coraza. Details about all three engine options can be found on our [engine options page]({{< ref "../deployment/engine_integration_options/#compatible-free-and-open-source-waf-engines" >}} "Page detailing the available CRS-compatible engines.").

A ModSecurity installation is presented in the examples below, however the install documentation for the Coraza engine can be found [here](https://www.coraza.io).

Two different methods to get an engine up and running are presented here:

- Using the chosen engine as provided and packaged by the OS distribution
- Compiling the chosen engine from source

### Installing Pre-packaged ModSecurity

ModSecurity is frequently pre-packaged and is available from several major Linux distributions.

- **Debian:** Friends of the CRS project [DigitalWave](https://modsecurity.digitalwave.hu) package and, most importantly, **keep ModSecurity updated** for Debian and its derivatives.
- **Fedora:** Install using the package manager: execute `dnf install mod_security` for Apache + ModSecurity v2.
- **RHEL compatible:** First install EPEL and then install ModSecurity using the package manager: execute `yum install mod_security`.

For Windows, the latest MSI package can be obtained from https://github.com/SpiderLabs/ModSecurity/releases.

{{% notice warning %}}
**Distributions might not update their ModSecurity releases frequently.**  As a result, it is quite likely that a distribution's version of ModSecurity may be missing important features or **may even contain security vulnerabilities**. Additionally, depending on the package and package manager used, the ModSecurity configuration will be laid out slightly differently.
{{% /notice %}}

As the different engines and distributions have different layouts for their configuration, to simplify the documentation presented here the prefix `<web server config>/` is used from this point on.

Examples of common `<web server config>/` paths include:

- `/etc/apache2` in Debian and derivatives
- `/etc/httpd` in RHEL and derivatives
- `/usr/local/apache2` if Apache was compiled from source using the default prefix
- `C:\Program Files\ModSecurity IIS\` (or 'Program Files (x86)', depending on configuration) on Windows
- `/etc/nginx` for Nginx

### Compiling ModSecurity from Source

An alternative to installing a pre-packaged version of ModSecurity is to compile it from source. This offers the maximum amount of flexibility.

Compiling ModSecurity is not difficult but is outside the scope of this document. For detailed information and instructions on how to compile ModSecurity, refer to the following:

- The official [ModSecurity documentation](https://github.com/SpiderLabs/ModSecurity/wiki "Link to the official ModSecurity documentation on GitHub.") on GitHub
- The compilation recipes for ModSecurity v3 on the [ModSecurity wiki](https://github.com/SpiderLabs/ModSecurity/wiki/Compilation-recipes-for-v3.x "Link to compilation recipes for ModSecurity v3 on the ModSecurity wiki.")
- The netnea tutorials for [Apache](https://www.netnea.com/cms/apache-tutorial-6_embedding-modsecurity/ "Link to a tutorial about compiling ModSecurity for Apache, on netnea.com.") or [Nginx](https://www.netnea.com/cms/nginx-tutorial-6_embedding-modsecurity/ "Link to a tutorial about compiling ModSecurity for Nginx, on netnea.com.")

{{% notice warning "Unsupported Configurations" "skull-crossbones" %}}
It is very important to note that the following configurations are **not** supported. They do **not** work as expected. The CRS project recommendation is to *avoid these setups*:

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

###### Microsoft IIS with ModSecurity 2.x

The initial configuration file is `modsecurity_iis.conf`. This file will be parsed by ModSecurity for both ModSecurity directives and `'Include'` directives.

Additionally, in the Event Viewer, under `Windows Logs\Application`, it should be possible to see a new log entry showing ModSecurity being successfully loaded.

At this stage, the ModSecurity on IIS setup is working and new directives can be placed in the configuration file as needed.

### Installing Coraza

The latest installation documentation for the Coraza engine can be found at [the Coraza website](https://www.coraza.io).

### Prerequisites

Installing the CRS isn't very difficult but does have one major requirement: *a compatible engine*. The reference engine used throughout this page is ModSecurity.

{{% notice note %}}
In order to successfully run CRS `3.x` using ModSecurity it is recommended to use the latest version available. For Nginx use the `3.x` branch of ModSecurity, and for Apache use the latest `2.x` branch.
{{% /notice %}}

## Option 3: Use a Pre-built WAF Solution

The simplest (but also most inflexible) option is to use a pre-built WAF solution, for example a commercial WAF appliance or a 'WAF-as-a-service' solution. This negates the need to install or compile a WAF engine. Examples of such solutions and services that are compatible with CRS can be found on the [engine and integration options]({{< ref "../deployment/engine_integration_options/#commercial-waf-appliances" >}} "Page giving examples of commercial WAF appliances in addition to cloud and CDN-based services.") page. Users should conduct their own research to determine whether such a solution meets their requirements.
