---
title: Plugin Mechanism
weight: 40
disableToc: false
chapter: false
---

> The CRS plugin mechanism allows the rule set to be extended in specific, experimental, or unusual ways, as this page explains.

{{% notice note %}}
Plugins are not part of the CRS 3.3.x release line. They are released officially with CRS 4.0. In the meantime, plugins _can_ be used with one of the stable releases by following the instructions presented below.
{{% /notice %}}

## What are Plugins?

Plugins are sets of additional rules that can be plugged in to a web application firewall in order to expand CRS with complementary functionality or to interact with CRS. **Rule exclusion plugins** are a special case: these are plugins that disable certain rules to integrate CRS in to a context that is otherwise likely to trigger certain false alarms.

## Why are Plugins Needed?

Installing only a minimal set of rules is desirable from a security perspective. A term often used is "minimizing the attack window". For CRS, this means that by having fewer rules, it is less likely to deploy a bug. In the past, CRS had a major bug in one of the rule exclusion packages which affected every standard CRS installation (see [CVE-2021-41773](https://coreruleset.org/20210630/cve-2021-35368-crs-request-body-bypass/)). By moving all rule exclusion packages into optional plugins, the risk is reduced in this regard. As such, security is a prime driver for the use of plugins.

A second driver is the need for certain functionality that does not belong in mainline CRS releases. Typical candidates include the following:

* ModSecurity features deemed too exotic for mainline, like the use of Lua scripting
* New rules that are not yet trusted enough to integrate into the mainline
* Specialized functionality with a very limited audience

A plugin might also evolve quicker than the slow release cycle of stable CRS releases. That way, a new and perhaps experimental plugin can be updated quickly.

Finally, there is a need to allow third parties to write plugins that interact with CRS. This was previously very difficult to manage, but with plugins everybody has the opportunity to write anomaly scoring rules.

## How do Plugins Work Conceptually?

Plugins are a set of rules. These rules can run in any phase, but in practice it is expected that most of them run in phase 1 and, especially, in phase 2, just like the rules in CRS. The rules of a plugin are separated into a rule file that is loaded *before* the CRS rules are loaded and a rule file with rules to be executed *after* the CRS rules are executed.

Optionally, a plugin can also have a separate configuration file with rules that configure the plugin, just like the `crs-setup.conf` configuration file.

The order of execution is as follows:

* CRS configuration
* Plugin configuration
* Plugin rules before CRS rules
* CRS rules
* Plugin rules after CRS rules

This can be mapped almost 1:1 to the `Includes` involved:

```apache
Include crs/crs-setup.conf
 
Include crs/plugins/*-config.conf
Include crs/plugins/*-before.conf
 
Include crs/rules/*.conf
 
Include crs/plugins/*-after.conf 
```

The two existing CRS `Include` statements are complemented with three additional generic plugin `Includes`. This means CRS is configured first, then the plugins are configured (if any), then the first batch of plugin rules are executed, followed by the main CRS rules, and finally the second batch of plugin rules run, after CRS.

## How to Install a Plugin

The first step is to prepare the plugin folder.

CRS 4.x will come with a plugins folder next to the rules folder. When using an older CRS release *without* a plugins folder, create one and place three empty config files in it (e.g. by using the shell command `touch`):

```
crs/plugins/empty-config.conf
crs/plugins/empty-before.conf
crs/plugins/empty-after.conf
```

These empty rule files ensure that the web server does not fail when `Include`-ing `*.conf` if there are no plugin files present.

{{% notice info %}}
Apache supports the `IncludeOptional` directive, but that is not available on *all* web servers, so `Include` is used here in the interests of having consistent and simple documentation.
{{% /notice %}}

For the installation, there are two methods:

### Method 1: Copying the plugin files

This is the simple way. Download or copy the plugin files, which are likely rules and data files, and put them in the plugins folder of the CRS installation, as prepared above.

There is a chance that a plugin configuration file comes with a `.example` suffix in the filename, like the `crs-setup.conf.example` configuration file in the CRS release. If that's the case then rename the plugin configuration file by removing the suffix.

Be sure to look at the configuration file and see if there is anything that needs to be configured.

Finally, reload the WAF and the plugin should be active.

### Method 2: Placing symbolic links to separate plugin files downloaded elsewhere

This is the more advanced setup and the one that's in sync with many Linux distributions.

With this approach, download the plugin to a separate location and put a symlink to each individual file in the plugins folder. If the plugin's configuration file comes with a `.example` suffix then that file needs to be renamed first.

With this approach it's easier to upgrade and downgrade a plugin by simply changing the symlink to point to a different version of the plugin. It's also possible to `git checkout` the plugin and pull the latest version when there's an update. It's not possible to do this in the plugins folder itself, namely when multiple plugins need to be installed side by side.

This symlink setup also makes it possible to `git clone` the latest version of a plugin and update it in the future without further ado. **Be sure to pay attention to any updates in the config file, however.**

If updating plugins this way, there's a chance of missing out a new variable that's defined in the latest version of the plugin's config file. Plugin authors should make sure this is not happening to plugin users by adding a rule that checks for the existence of all config variables in the *Before-File*. Examples of this can be found in CRS file `REQUEST-901-INITIALIZATION.conf`.

## How to Disable a Plugin

Disabling a plugin is simple. Either remove the plugin files in the plugins folder or, if installed using the symlink method, remove the symlinks to the real files. Working with symlinks is considered to be a 'cleaner' approach, since the plugin files remain available to re-enable in the future.

Alternatively, it is also valid to disable a plugin by renaming a plugin file from `plugin-before.conf` to `plugin-before.conf.disabled`.

## Conditionally enable plugins for multi-application environments

If CRS is installed on a reverse-proxy or a web server with multiple web applications, then you may wish to only enable certain plugins (such as rule exclusion plugins) for certain virtual hosts (`VirtualHost` for Apache httpd, `Server` context for Nginx). This ensures that rules designed for a specific web application are only enabled for the intended web application, reducing the scope of any possible bypasses within a plugin.

Most plugins provide an example to disable the plugin in the file `plugin-config.conf`, you can define the `WebAppID` variable for each virtual host and then disable the plugin when the `WebAppID` variable doesn't match.

See: https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)#secwebappid

Below is an example for enabling only the WordPress plugin for WordPress virtual hosts:

```
SecRule &TX:wordpress-rule-exclusions-plugin_enabled "@eq 0" \
    "id:9507010,\
    phase:1,\
    pass,\
    nolog,\
    ver:'wordpress-rule-exclusions-plugin/1.0.0',\
    chain"
    SecRule WebAppID "!@streq wordpress" \
        "t:none,\
        setvar:'tx.wordpress-rule-exclusions-plugin_enabled=0'"
```

⚠️ Warning: As of 05/06/2024, Coraza doesn't support the use of WebAppID, you can use the`Host` header instead of the `WebAppID` variable:

```
SecRule &TX:wordpress-rule-exclusions-plugin_enabled "@eq 0" \
    "id:9507010,\
    phase:1,\
    pass,\
    nolog,\
    ver:'wordpress-rule-exclusions-plugin/1.0.0',\
    chain"
    SecRule REQUEST_HEADERS:Host "!@streq wordpress.example.com" \
        "t:none,\
        setvar:'tx.wordpress-rule-exclusions-plugin_enabled=0'"
```

See: https://coraza.io/docs/seclang/variables/#webappid

## What Plugins are Available?

All official plugins are listed on GitHub in the CRS plugin registry repository: https://github.com/coreruleset/plugin-registry.

Available plugins include:

* **Template Plugin:** This is the example plugin for getting started.
* **Auto-Decoding Plugin:** This uses ModSecurity transformations to decode encoded payloads before applying CRS rules at PL 3 and double-decoding payloads at PL 4.
* **Antivirus Plugin:** This helps to integrate an antivirus scanner into CRS.
* **Body-Decompress Plugin:** This decompresses/unzips the response body for inspection by CRS.
* **Fake-Bot Plugin:** This performs a reverse DNS lookup on IP addresses pretending to be a search engine.
* **Incubator Plugin:** This plugin allows non-scoring rules to be tested in production before pushing them into the mainline.

## How to Write a Plugin

For information on writing a new plugin, refer to the development documentation on [writing plugins]({{% ref "plugin_writing.md" %}}).

## Collection Timeout

If plugins need to work with collections and set a custom `SecCollectionTimeout` outside of the default 3600 seconds defined by the ModSecurity engine, the plugin should either set it in its configuration or indicate the desired value in the plugin documentation. CRS used to define `SecCollectionTimeout` in `crs-setup.conf` before but removed this setting with the introduction of plugins for CRS v4. That's because CRS itself does not work with collections anymore. 
