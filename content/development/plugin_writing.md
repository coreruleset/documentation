---
title: Writing Plugins
weight: 50
disableToc: false
chapter: false
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

### Plugin Use of Persistent Collections: ModSecurity SecCollectionTimeout
If a plugin uses persistent collections (stores stateful information across multiple requests, e.g., to implement DoS protection functionality), it is important to note that CRS does not change the default value (`3600`) for the ModSecurity `SecCollectionTimeout` directive. Plugin authors must instruct users to set the directive to an appropriate value if the plugin requires a value that differs from the default. A plugin should never actively set `SecCollectionTimeout`, as other plugins may specify different values for the directive and the choice for the effective value must be made by the user.

## Quality Guarantee

The official CRS plugins are separated from third party plugins. The rationale is to keep the quality of official plugins on par with the quality of the CRS project itself. It's not possible to guarantee the quality of third party plugins as their code is not under the control of the CRS project. Third party plugins should be examined and considered separately to decide whether their quality is sufficient for use in production.

## How to Integrate a Plugin into the Official Registry

Plugins should be developed and refined until they are production-ready. The next step is to open a pull request at the [plugin registry](https://github.com/coreruleset/plugin-registry). Any free rule ID range can be used for a new plugin. The plugin will then be reviewed and assigned a block of rule IDs. Afterwards, the plugin will be listed as a new third party plugin.
