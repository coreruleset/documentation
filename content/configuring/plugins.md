---
title: "Plugin Mechanism"
chapter: false
weight: 19
---

> The CRS plugin mechanism allows the rule set to be extended in specific, experimental, or unusual ways, as this page explains.

{{% notice note %}}
Plugins are not part of the CRS 3.3.x release line. They will be released officially with the next major CRS release. In the meantime, plugins can be used with one of the stable releases by following the instructions presented below.
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

Future CRS releases will come with a plugins folder next to the rules folder. If using a CRS release *without* a plugins folder, create one and place three empty config files in it (e.g. by using the shell command `touch`):

```
crs/plugins/empty-config.conf
crs/plugins/empty-before.conf
crs/plugins/empty-after.conf
```

These empty rule files ensure that the web server does not fail when `Include`-ing `*.conf` if there are no plugins present.

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

## What Plugins are Available?

All official plugins are listed on GitHub in the CRS plugin registry repository: https://github.com/coreruleset/plugin-registry.

Available plugins include:

* **Dummy Plugin:** This is the example plugin for getting started.
* **Auto-Decoding Plugin:** This uses ModSecurity transformations to decode encoded payloads before applying CRS rules at PL 3 and double-decoding payloads at PL 4.
* **Antivirus Plugin:** This helps to integrate an antivirus scanner into CRS.
* **Body-Decompress Plugin:** This decompresses/unzips the response body for inspection by CRS.
* **Fake-Bot Plugin:** This performs a reverse DNS lookup on IP addresses pretending to be a search engine.
* **Incubator Plugin:** This plugin allows non-scoring rules to be tested in production before pushing them into the mainline.

## How to Write a Plugin

### Is a Plugin the Right Approach for a Given Rule Problem?

This is the first and most important question to ask.

CRS is a generic rule set. The rule set has no awareness of the particular setup it finds itself deployed in. As such, the rules are written with caution and administrators are given the ability to steer the behavior of CRS by setting the anomaly threshold accordingly. *An administrator writing their own rules knows a lot more about their specific setup*, so there's probably no need to be as cautious. It's also probably futile to write anomaly scoring rules in this situation. Anomaly scoring adds little value if an administrator knows that everybody issuing a request to `/no-access`, for example, is an attacker.

In such a situation, it's better to write a simple deny-rule that blocks said requests. There's no need for a plugin in most situations.

### Plugin Writing Guidance

When there really *is* a good use case for a plugin, it's recommended to start with a clone of the dummy plugin. It's well documented and a good place to start from.

Plugins are a new idea for CRS. As such, there aren't currently any strict rules about what a plugin is and isn't allowed to do. There are definitely fewer rules and restrictions for writing plugin rules than for writing a mainline CRS rule, which is becoming increasingly strict as the project evolves. This means that it's basically possible to do anything in a plugin, especially when there's no plan to contribute the plugin to the CRS project.

When it *is* planned to contribute a plugin back to the CRS project, the following guidance will help:

* Try to keep plugins separate. Try not to interfere with other plugins and make sure that any other plugin can run next to yours.
* Be careful when interfering with CRS. It's easy to disrupt CRS by excluding essential rules or by messing with variables.
* Keep an eye on performance and think of use cases.

### Anomaly Scoring: Getting the Phases Right

The anomaly scores are only initialized in the CRS rules file `REQUEST-901-INITIALIZATION.conf`. This happens in phase 1, but it still happens *after* a plugin's `*-before.conf` file has been executed for phase 1. As a consequence, if anomaly scores are set there then they'll be overwritten in CRS phase 1.

The effect for phase 2 anomaly scoring in a plugin's `*-after.conf` file is similar. It happens after the CRS request blocking happens in phase 2. This can mean a plugin raises the anomaly score *after* the blocking decision. This might result in a higher anomaly score in the log file and confusion as to why the request was not blocked.

What to do is as follows:

* **Scoring in phase 1:** Put in the plugin's *After-File* (and be aware that early blocking won't work).
* **Scoring in phase 2:** Put in the plugin's *Before-File*.

## Quality Guarantee

The official CRS plugins are separated from third party plugins. The rationale is to keep the quality of official plugins on par with the quality of the CRS project itself. It's not possible to guarantee the quality of third party plugins as their code is not under the control of the CRS project. Third party plugins should be examined and considered separately to decide whether their quality is sufficient for use in production.

## How to Integrate a Plugin into the Official Registry

Plugins should be developed and refined until they are production-ready. The next step is to open a pull request at the [plugin registry](https://github.com/coreruleset/plugin-registry). Any free rule ID range can be used for a new plugin. The plugin will then be reviewed and assigned a block of rule IDs. Afterwards, the plugin will be listed as a new third party plugin.
