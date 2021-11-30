---
title: "Rule Exclusions"
chapter: false
weight: 18
---

> When a *genuine* transaction causes a rule form the Core Rule Set to match in error it is described as a **false positive**. False positives need to be tuned away by writing *rule exclusions*, which this page explains.

## What are False Positives?

The Core Rule Set provides _generic_ attack detection capabilities. A fresh CRS deployment has no awareness of the web services that may be behind it, or the quirks of how those services work. It is possible that *genuine* transactions may cause some CRS rules to match in error, if the transactions happen to match one of the generic attack behaviors or patterns that are being detected. Such a match is referred to as a *false positive*, or false alarm.

False positives are particularly likely to happen when operating at higher [paranoia levels]({{< ref "paranoia_levels" >}} "Page describing paranoia levels."). While paranoia level 1 is designed to cause few, ideally zero, false positives, higher paranoia levels are increasingly likely to cause false positives. Each successive paranoia level introduces additional rules, with *higher* paranoia levels adding *more aggressive* rules. As such, the higher the paranoia level is the more likely it is that false positives will occur. That is the cost of higher security provided by higher paranoia levels: the time it takes to tune away the increasing number of false positives.

### An Example

Imagine deploying the CRS in front of a WordPress instance. The WordPress engine features the ability to add HTML to blog posts (as well as JavaScript, if you're an administrator). Internally, WordPress has rules controlling which HTML tags are allowed to be used. This list of allowed tags has been studied heavily by the security community and it's considered to be a secure mechanism.

Consider the CRS inspecting a request with a URL like the following:

```
www.mywordpressblog.com/?wp_post=<h1>Welcome+To+My+Blog</h1>
```

At paranoia level 2, the `wp_post` query string parameter would trigger a match against an XSS attack rule due to the presence of HTML tags. CRS is unaware that the problem is properly mitigated on the server side and, as a result, the request causes a false positive and may be blocked.

{{% notice tip %}}
TODO Mention the WordPress RE package.
{{% /notice %}}

### Why are False Positives a Problem?

#### Alert Fatigue

If a system is prone to reporting false positives then the alerts it raises may be ignored. This may lead to real attacks being overlooked. For this reason, leaving false positives mixed in with real attacks is dangerous: the false positives must be resolved.

#### Poor User Experience

When working in blocking mode, false positives can cause legitimate user transactions to be blocked, leading to poor user experience. This can create pressure to disable the CRS or even to remove the WAF solution entirely. This is an unnecessary sacrifice of security for usability: tuning away the false positives is the correct solution to this problem.

## Tuning Away False Positives

### Directly Modifying CRS Rules

{{% notice warning %}}
This is a bad idea and is not recommended.
{{% /notice %}}

It may seem logical, at first, to prevent false positives by modifying the offending CRS rules. **This is a bad idea.**

*Directly modifying CRS rules essentially creates a fork of the rule set.* Any modifications made would be undone by a rule set update, meaning that any changes would need to be continually reapplied by hand. This is a tedious and error-prone solution.

### Rule Exclusions

#### Overview

The ModSecurity WAF engine provides several *rule exclusion* mechanisms which allow rules to be modified *without* directly changing the rules themselves. This makes it possible to work with third-party rule sets, like the Core Rule Set, by adapting rules as needed while leaving the rule set files intact and unmodified. This allows for easy rule set updates.

Two fundamentally different types of rule exclusions are supported:

- **Configure-time rule exclusions:** Rule exclusions that are applied once, at *configure-time* (e.g. when (re)starting or reloading ModSecurity, or the server process that holds it).
- **Runtime rule exclusions:** Rule exclusions that are applied at *runtime* on a per-transaction basis (e.g. exclusions that can be conditionally applied to some transactions but not others).

In addition to the two *types* of exclusions, rules can be excluded in two different *ways*:

- **Exclude the entire rule:** An entire rule is disabled and will not be executed by the rule engine.
- **Exclude a specific parameter from the rule:** A *specific parameter* will be excluded from a specific rule.

This is summarized in the table below, which presents different directives and actions that can be used for each type and method of rule exclusion:

|                    | Exclude entire rule  | Exclude specific parameter from rule |
| ------------------ | -------------------- | ------------------------------------ |
| **Configure-time** | `SecRuleRemoveById`  | `SecRuleUpdateTargetById`            |
| **Runtime**        | `ctl:ruleRemoveById` | `ctl:ruleRemoveTargetById`           |

{{% notice tip %}}
This information is available as a well-presented, downloadable [Rule Exclusion Cheatsheet](https://www.netnea.com/cms/rule-exclusion-cheatsheet-download) over at netnea.com
{{% /notice %}}

### Exceptions versus Whitelist

There are two generally different methods for modifying rules.
Exceptions, which will remove or modify the rule from startup time and
whitelist modifications which can modify a rule based on the content of
a transaction. In general whitelist rules are slightly more powerful but
also more expensive as they must be evaluated every time a transaction
comes in.

Within CRS 3.x two files are provided to help you add these different
rule modifications, they are:
`rules/REQUEST-00-LOCAL-WHITELIST.conf.example` and
rules/RESPONSE-99-EXCEPTIONS.conf.example. As is noted in the
[install]({{< ref "install.md" >}}) documentation, the .example
extension is provided specifically so that when these files are renamed,
future updates will not overwrite these files. Before adding a
whitelist or exception modification you should rename these files to end
in the .conf exception.

The naming of these files is also not an accident. Due to the
transactional nature of the whitelist modifications, they need to take
place BEFORE the rules they are affecting, since they are processed on
every transaction. Conversely, the exceptions file contains directives
that are evaluated on startup. As a result, these need to be some of the
last rules included in your configuration such that data structures that
store the rules are populated and it can modify them.

### Writing Exceptions

Exceptions come in a few different forms which are all outlined in
detail within the [Reference Manual](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)).
The following directives can be used to modify a rule at startup without
touching the actual rule:

-   [SecRuleRemoveById](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveById)
-   [SecRuleRemoveByMsg](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveByMsg)
-   [SecRuleRemoveByTag](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveByTag)
-   [SecRuleUpdateActionById](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleUpdateTargetById)
-   [SecRuleUpdateTargetById](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleUpdateTargetById)
-   [SecRuleUpdateTargetByMsg](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleUpdateTargetByMsg)
-   [SecRuleUpdateTargetByTag](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleUpdateTargetByTag)

You'll notice that there are two types of exceptions, those that
remove, and those that change (or update) rules. General usage of the
`SecRuleRemove*` rules is fairly straight forward:

```apache
SecRule ARGS "@detectXSS" "id:123,deny,status:403"
SecRuleRemoveById 123
```

The above rule will remove rule 123. When ModSecurity starts up it will
add rule 123 into its internal data structures and when it processes
SecRuleRemoveById it will then remove it from it's internal data
structures. The rule will not be processed for any transaction as by the
time ModSecurity reaches the point where it's processing requests, the
rule simply no longer exists.

The `SecRuleUpdate*` modifications are a bit more complicated. They have
the capability to update a target or action based on some identifier.
The update target rule is perhaps the simpler of the two to use.
Modifying Targets (Variables) is easy, you can either append or replace.
To append you simply only list one argument after
`SecRuleUpdateTargetBy*`. This is great for adding exceptions as you can
restrict a certain index of a collection from being inspected

```apache
SecRule ARGS "@detectXSS" "id:123,deny,status:403"
SecRuleUpdateTargetById 123 !ARGS:wp_post
```

It is also possible to replace a target (variable). To do this you must
first list the variable you want to replace with, followed by the
variable you want to replace. So in the below example we replace the
ARGS variable with ARGS_POST.

```apache
SecRule ARGS "@detectXSS" "id:123,deny,status:403"
SecRuleUpdateTargetById 123 ARGS_POST ARGS
```

Updating an action becomes a little more tricky as there are default
actions and actions types of which only one can exist per rule. In
general, transformations and actions that are not already included will
be appended. There is one big exception to this rule and that is
disruptive actions (pass, deny, etc) will always replace each other,
there may only ever be one disruptive action. Additionally, certain
logging actions will replace each other, for instance nolog would
overwrite the log action. This functionality has the same rules as using
[SecDefaultAction](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecDefaultAction).

```apache
SecRule "@detectXSS" attack "phase:2,id:12345,t:lowercase,log,pass,msg:'Message text'"
SecRuleUpdateActionById 12345 "t:none,t:compressWhitespace,deny,status:403,msg:'New message text'"

# Results in the following rule
SecRule ARGS "@detectXSS "phase:2,id:12345,t:lowercase,t:none,t:compressWhitespace,log,deny,status:403,msg:'New Message text'"
```

In general updating a rule to remove just the false positive is
preferred over removing the entire rule. It should be noted that both
actions should be taken with care as they do open a potential security
hole. Before you add an exception within any rules you should make sure
that the area where you are adding the exception is indeed a false
positive and not vulnerable to the issue.

You may notice that it is not possible to change the operator of the
rule via these exception Directives. To change the functionality of a
rule you must use whitelist modifications OR remove the rule and add a
new one.

### Writing Whitelist Modifications

Whitelisting is more complicated than exceptions because the rules can
be more varied. In some ways they are less powerful than exceptions, but
in others they are far more powerful. Whitelist rules use the
[ctl](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#ctl)
action to change the state of the engine on a per transaction basis.
This can be as simple as turning off the ruleEngine when a certain IP
hits. Note, the ruleEngine will return to state from the configuration
file for the next transaction.

```apache
SecRule REMOTE_ADDR "@IPMatch 1.2.3.4" "id:1,ctl:ruleEngine=Off"
```

You can also use this rule to avoid certain rules in some cases, this
effectively allows you to modify operators. In the following example we
have a rule that will block the entire 129.21.x.x subnet (class B). We
add a ctl modification before hand such that if we get a particular IP
address in that range we remove the rule, effectively adding an
exception

```apache
SecRule REMOTE_ADDR "@IPMatch 129.21.3.17" "id:3,ctl:ruleRemoveById=4"
SecRule REMOTE_ADDR "@IPMatch 129.21.0.0/24" "id:4,deny,status:403"
```

The
[ctl](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#ctl)
action can also change the configuration of certain directives which can
lead to more efficient rules. It is recommended that you investigate its
full potential.

Tuning CRS
----------

CRS 3.x is designed to make it easy to remove rules that are not
relevant to your configuration. Not only are Rules organized into files
that are titled with general categories but we have also renumbered
according to a scheme such that rule IDs can be used to quickly remove
entire unwanted configurations files by using
[SecRuleRemoveById](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveById).
The following example removes all XSS rules which are located in the
`REQUEST-941-APPLICATION-ATTACK-XSS.conf` file. Notice that all OWASP CRS
rules are prefixed with '9' and then the next two digits represent the
rules file.

```apache
SecRuleRemoveById "941000-941999"
```

The CRS rules also features tags to identify what their functionality
is. It is therefore easy to remove an entire category that doesn\'t
apply to your environment. In the following example we remove all IIS
rules using
[SecRuleRemoveByTag](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveByTag).

```apache
SecRuleRemoveByTag "platform-iis"
```

## TODO: RE Packages

## TODO: Link to netnea

