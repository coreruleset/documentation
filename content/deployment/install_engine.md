---
title: "Installing a Compatible Engine"
weight: 15
disableToc: false
chapter: false
---

> The first step to a fully functional CRS installation is to have a compatible *engine* in place. The engine provides the tools and functionality to parse and inspect web traffic. This page walks through installing some common options.

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
