---
title: Writing Plugins
weight: 42
disableToc: false
chapter: false
aliases: ["../development/plugin_writing"]
---

> The CRS plugin mechanism allows the rule set to be extended in specific, experimental, or unusual ways. This page explains how to write a new plugin to extend CRS.

## How to Write a Plugin

### Is a Plugin the Right Approach for a Given Rule Problem?

This is the first and most important question to ask.

CRS is a generic rule set. The rule set has no awareness of the particular setup it finds itself deployed in. As such, the rules are written with caution and administrators are given the ability to steer the behavior of CRS by setting the anomaly threshold accordingly. *An administrator writing their own rules knows a lot more about their specific setup*, so there's probably no need to be as cautious. It's also probably futile to write anomaly scoring rules in this situation. Anomaly scoring adds little value if an administrator knows that everybody issuing a request to `/no-access`, for example, is an attacker.

In such a situation, it's better to write a simple deny-rule that blocks said requests. There's no need for a plugin in most situations.

### Plugin Writing Guidance

When there really *is* a good use case for a plugin, it's recommended to start with a clone of the [template plugin](https://github.com/coreruleset/template-plugin). It's well documented and a good place to start from.

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

### Adding Entries to CRS Lists

Some plugins need to allow more than CRS does by default, for example the WebDAV methods `PROPFIND` and `MKCOL`, or an additional content type. Since CRS 4.31.0, plugins do this with their own variables, following the [plugin contract](https://github.com/coreruleset/coreruleset/blob/main/PLUGIN-CONTRACT.md).

A plugin must not set `tx.allowed_methods` or the other CRS lists directly. Plugins are loaded before `REQUEST-901-INITIALIZATION.conf`, and CRS only sets a default when the variable does not exist yet. A plugin that sets the list itself either skips the CRS defaults or has to copy them, and the copy gets outdated when CRS changes a default.

Instead, each plugin rule writes its additions to its own variable, named after the list and the rule ID:

```
tx.plugin_<list>_<rule id>
```

For example, the Nextcloud plugin allows the WebDAV methods only for its WebDAV endpoints:

```apache
# nextcloud-rule-exclusions-before.conf
SecRule REQUEST_FILENAME "@rx /(?:remote|public)\.php/dav/" \
    "id:9508190,\
    phase:1,\
    pass,\
    t:none,\
    nolog,\
    ver:'nextcloud-rule-exclusions-plugin/x.y.z',\
    setvar:'tx.plugin_allowed_methods_9508190=|PROPFIND| |PROPPATCH| |MKCOL| |MOVE| |COPY| |LOCK| |UNLOCK| |REPORT|'"
```

After the defaults are set, CRS collects all these variables and appends them to the lists (rules 901600 to 901660). So plugins that follow the contract don't overwrite each other, and the CRS defaults and the user's settings stay in place.

The most important rules:

* Set the variables in the *Before-File* and in phase 1.
* Use the format of the list: `|METHOD|`, `|HTTP/x|`, `|type/subtype|`, `|charset|`, `.ext/` or `/header-name/`.
* Write content types, charsets, extensions and header names in lowercase. Methods and HTTP versions use the exact case that is sent. An entry in the wrong case never matches, and no error is reported.
* Limit additions to where they are needed, for example to a path.
* When adding a content type, also select the matching body processor (`JSON`, `XML` or `URLENCODED`) for exactly these requests. Otherwise the body is not parsed, and CRS can't see attacks in it.
* Plugins can only add entries. To allow something that a `restricted_*` list blocks, a plugin still needs a rule exclusion.

The [plugin contract](https://github.com/coreruleset/coreruleset/blob/main/PLUGIN-CONTRACT.md) lists all supported lists, their formats and the guarantees CRS gives.

{{% notice note %}}
CRS releases before 4.31.0 ignore the `tx.plugin_*` variables. As long as a plugin also supports these releases (for example the current LTS), it may set any of the CRS lists directly, with two conditions:

* It must use the format of the list, both for the copy of the CRS default and for the entries it appends. For methods and HTTP versions, this is the pipe format (`|GET| |HEAD| |POST| |OPTIONS|`), which works with old and new CRS releases. A list in the old space-separated format blocks every request on CRS 4.31.0 and later.
* It must limit the direct change to the requests that need it, for example to the plugin's paths. A direct assignment replaces the whole list for that request, including the list the user set in `crs-setup.conf`.

This is temporary. As soon as a plugin no longer supports CRS releases before 4.31.0, it must use the `tx.plugin_*` variables. See section 9.3 of the contract.
{{% /notice %}}

### Plugin Use of Persistent Collections: ModSecurity SecCollectionTimeout
If a plugin uses persistent collections (stores stateful information across multiple requests, e.g., to implement DoS protection functionality), it is important to note that CRS does not change the default value (`3600`) for the ModSecurity `SecCollectionTimeout` directive. Plugin authors must instruct users to set the directive to an appropriate value if the plugin requires a value that differs from the default. A plugin should never actively set `SecCollectionTimeout`, as other plugins may specify different values for the directive and the choice for the effective value must be made by the user.

## Quality Guarantee

The official CRS plugins are separated from third party plugins. The rationale is to keep the quality of official plugins on par with the quality of the CRS project itself. It's not possible to guarantee the quality of third party plugins as their code is not under the control of the CRS project. Third party plugins should be examined and considered separately to decide whether their quality is sufficient for use in production.

## How to Integrate a Plugin into the Official Registry

Plugins should be developed and refined until they are production-ready. The next step is to open a pull request at the [plugin registry](https://github.com/coreruleset/plugin-registry). Any free rule ID range can be used for a new plugin. The plugin will then be reviewed and assigned a block of rule IDs. Afterwards, the plugin will be listed as a new third party plugin.
