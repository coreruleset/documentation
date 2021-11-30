---
title: "False Positives and Tuning"
chapter: false
weight: 18
---

> When a *genuine* transaction causes a rule form the Core Rule Set to match in error it is described as a **false positive**. False positives need to be tuned away by writing *rule exclusions*, as this page explains.

## What are False Positives?

The Core Rule Set provides _generic_ attack detection capabilities. A fresh CRS deployment has no awareness of the web services that may be running behind it, or the quirks of how those services work. It is possible that *genuine* transactions may cause some CRS rules to match in error, if the transactions happen to match one of the generic attack behaviors or patterns that are being detected. Such a match is referred to as a *false positive*, or false alarm.

False positives are particularly likely to happen when operating at higher [paranoia levels]({{< ref "paranoia_levels" >}} "Page describing paranoia levels."). While paranoia level 1 is designed to cause few, ideally zero, false positives, higher paranoia levels are increasingly likely to cause false positives. Each successive paranoia level introduces additional rules, with *higher* paranoia levels adding *more aggressive* rules. As such, the higher the paranoia level is the more likely it is that false positives will occur. That is the cost of higher security provided by higher paranoia levels: the additional time it takes to tune away the increasing number of false positives.

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

If a system is prone to reporting false positives then the alerts it raises may be ignored. This may lead to real attacks being overlooked. For this reason, leaving false positives mixed in with real attacks is dangerous: the false positives should be resolved.

#### Poor User Experience

When working in blocking mode, false positives can cause legitimate user transactions to be blocked, leading to poor user experience. This can create pressure to disable the CRS or even to remove the WAF solution entirely, which is an unnecessary sacrifice of security for usability. The correct solution to this problem is to tune away the false positives so that they don't reoccur in the future.

## Tuning Away False Positives

### Directly Modifying CRS Rules

{{% notice warning %}}
Making direct modifications to CRS rule files is a bad idea and is strongly discouraged.
{{% /notice %}}

It may seem logical to prevent false positives by modifying the offending CRS rules. If a detection pattern in a CRS rule is causing matches with genuine transactions then the pattern could be modified. **This is a bad idea.**

*Directly modifying CRS rules essentially creates a fork of the rule set.* Any modifications made would be undone by a rule set update, meaning that any changes would need to be continually reapplied by hand. This is a tedious, time consuming, and error-prone solution.

### Rule Exclusions

#### Overview

The ModSecurity WAF engine has flexible ways to tune away false positives. It provides several *rule exclusion* (RE) mechanisms which allow rules to be modified *without* directly changing the rules themselves. This makes it possible to work with third-party rule sets, like the Core Rule Set, by adapting rules as needed while leaving the rule set files intact and unmodified. This allows for easy rule set updates.

Two fundamentally different types of rule exclusions are supported:

- **Configure-time rule exclusions:** Rule exclusions that are applied once, at *configure-time* (e.g. when (re)starting or reloading ModSecurity, or the server process that holds it). For example: "remove rule X at startup and never execute it."

  This type of rule exclusion takes the form of a ModSecurity directive, e.g. `SecRuleRemoveById`.

- **Runtime rule exclusions:** Rule exclusions that are applied at *runtime* on a per-transaction basis (e.g. exclusions that can be conditionally applied to some transactions but not others). For example: "if a transaction is a POST request to the location 'login.php', remove rule X."

  This type of rule exclusion takes the form of a `SecRule`.

{{% notice info %}}
Runtime rule exclusions, while granular and flexible, have a computational cost associated to them. A runtime rule exclusion is an extra SecRule which must be evaluated for every transaction.
{{% /notice %}}

In addition to the two *types* of exclusions, rules can be excluded in two different *ways*:

- **Exclude the entire rule:** An entire rule is removed and will not be executed by the rule engine.
- **Exclude a specific variable from the rule:** A *specific variable* will be excluded from a specific rule.

The combinations of rule exclusion types and methods allow for writing rule exclusions of varying granularity. Very coarse rule exclusions can be written, for example "remove all SQL injection rules" using `SecRuleRemoveByTag`. Extremely granular rule exclusions can also be written, for example "for transactions to the location 'web_app_2/function.php', exclude the query string parameter 'user_id' from rule 920280" using a SecRule and the action `ctl:ruleRemoveTargetById`.

The different rule exclusion types and methods are summarized in the table below, which presents the main ModSecurity directives and actions that can be used for each type and method of rule exclusion:

|                    | Exclude entire rule                            | Exclude specific variable from rule                    |
| ------------------ | ---------------------------------------------- | ------------------------------------------------------ |
| **Configure-time** | `SecRuleRemoveById`\* `SecRuleRemoveByTag`     | `SecRuleUpdateTargetById` `SecRuleUpdateTargetByTag`   |
| **Runtime**        | `ctl:ruleRemoveById`\*\* `ctl:ruleRemoveByTag` | `ctl:ruleRemoveTargetById` `ctl:ruleRemoveTargetByTag` |

*\*Can also exclude ranges of rules or multiple space separated rules.*

*\*\*Can also exclude ranges of rules.*

{{% notice tip %}}
This table is available as a well presented, downloadable [Rule Exclusion Cheatsheet](https://www.netnea.com/cms/rule-exclusion-cheatsheet-download) at netnea.com
{{% /notice %}}

#### Rule Ranges

As well as rules being tagged using different categories, CRS rules are organized into files by general category. In addition, CRS rule IDs follow a consistent numbering convention. This makes it easy to remove unwanted types of rules by removing ranges of rule IDs. For example, the file `REQUEST-933-APPLICATION-ATTACK-PHP.conf` contains the PHP related rules, which all have rule IDs in the range 933000-933999. All of the rules in this file can be easily removed by using a configure-time rule exclusion like so:

```apache
SecRuleRemoveById "933000-933999"
```

#### Placement of Rule Exclusions

**It is crucial to put rule exclusions in the correct place, otherwise they may not work.**

- **Configure-time rule exclusions:** These must be placed **after** the CRS has been included in a configuration. For example:

  ```apache
  # Include the ModSecurity Core Rule Set
  Include crs/rules/*.conf

  # Configure-time rule exclusions
  ...
  ```

  Configure-time rule exclusions *remove* rules. A rule must already be defined before it can be removed (something cannot be removed if it doesn't yet exist). As such, this type of rule exclusion must appear *after* the CRS and all its rules have been included.

- **Runtime rule exclusions:** These must be placed **before** the CRS has been included in a configuration. For example:

  ```apache
  # Runtime rule exclusions
  ...

  # Include the ModSecurity Core Rule Set
  Include crs/rules/*.conf
  ```

  Runtime rule exclusions *modify* rules in some way. If a rule is to be modified then this should occur before the rule is executed (modifying a rule *after* it has been executed has no effect). As such, this type of rule exclusion must appear *before* the CRS and all its rules have been included.

{{% notice tip %}}
CRS ships with the files `REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example` and `RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example`. After dropping the ".example" suffix, these files can be used to house "BEFORE-CRS" (i.e. runtime) and "AFTER-CRS" (i.e. configure-time) rule exclusions in their correct places relative to the CRS rules. These files also contain example rule exclusions to copy and learn from.
{{% /notice %}}

#### Example 1 *(SecRuleRemoveById)*

*(Configure-time RE. Exclude entire rule.)*

**Scenario:** Rule 933151, "PHP Injection Attack: Medium-Risk PHP Function Name Found", is causing false positives. The web application behind the WAF makes no use of PHP. As such, it is deemed safe to tune away this false positive by completely removing rule 933151.

**Rule Exclusion:**

```apache
# CRS Rule Exclusion: 933151 - PHP Injection Attack: Medium-Risk PHP Function Name Found
SecRuleRemoveById 933151
```

#### Example 2 *(SecRuleRemoveByTag)*

*(Configure-time RE. Exclude entire rule.)*

**Scenario:** Several different parts of a web application are causing false positives with various SQL injection rules. None of the web services behind the WAF make use of SQL, so it is deemed safe to tune away these false positives by removing all the SQLi detection rules.

**Rule Exclusion:**

```apache
# CRS Rule Exclusion: Remove all SQLi detection rules
SecRuleRemoveByTag attack-sqli
```

#### Example 3 *(SecRuleUpdateTargetById)*

*(Configure-time RE. Exclude specific variable from rule.)*

**Scenario:** The content of a POST body parameter named 'text_input' is causing false positives with rule 941150, "XSS Filter - Category 5: Disallowed HTML Attributes". Removing this rule entirely is deemed to be unacceptable: the rule is not causing any other issues, and the protection it provides should be retained for everything apart from 'text_input'. It is decided to tune away this false positive by excluding 'text_input' from rule 941150.

**Rule Exclusion:**

```apache
# CRS Rule Exclusion: 941150 - XSS Filter - Category 5: Disallowed HTML Attributes
SecRuleUpdateTargetById 941150 "!ARGS:text_input"
```

#### Example 4 *(SecRuleUpdateTargetByTag)*

*(Configure-time RE. Exclude specific variable from rule.)*

**Scenario:** The values of request cookies with random names of the form 'uid_\<STRING\>' are causing false positives with various SQL injection rules. It is decided that it is not a risk to allow SQL-like content in cookie values, however it is deemed unacceptable to disable the SQLi detection rules for anything apart from the request cookies in question. It is decided to tune away these false positives by excluding only the problematic request cookies from the SQLi detection rules.

**Rule Exclusion:**

```apache
# CRS Rule Exclusion: Exclude the request cookies 'uid_<STRING>' from the SQLi detection rules
SecRuleUpdateTargetByTag attack-sqli "!REQUEST_COOKIES:/^uid_.*/"
```

#### Example 5 *(ctl:ruleRemoveById)*

*(Runtime RE. Exclude entire rule.)*

**Scenario:** Rule 920230, "Multiple URL Encoding Detected", is causing false positives at the specific location '/webapp/function.php'. This is being caused by a known quirk in how the web application has been written, and it cannot be fixed in the application. It is deemed safe to tune away this false positive by removing rule 920230 for that specific location only.

**Rule Exclusion:**

```apache
# CRS Rule Exclusion: 920230 - Multiple URL Encoding Detected
SecRule REQUEST_URI "@beginsWith /webapp/function.php" \
    "id:1000,\
    phase:1,\
    pass,\
    nolog,\
    ctl:ruleRemoveById=920230"
```

#### Example 6 *(ctl:ruleRemoveByTag)*

*(Runtime RE. Exclude entire rule.)*

**Scenario:** Several different locations under '/web_app_1/content' are causing false positives with various SQL injection rules. Nothing under that location makes any use of SQL, so it is deemed safe to remove all the SQLi detection rules for that location. Other locations *may* make use of SQL, however, so the SQLi detection rules **must** remain in place everywhere else. It has been decided to tune away the false positives by removing all the SQLi detection rules for locations under '/web_app_1/content' only.

**Rule Exclusion:**

```apache
# CRS Rule Exclusion: Remove all SQLi detection rules
SecRule REQUEST_URI "@beginsWith /web_app_1/content" \
    "id:1010,\
    phase:1,\
    pass,\
    nolog,\
    ctl:ruleRemoveByTag=attack-sqli"
```

#### Example 7 *(ctl:ruleRemoveTargetById)*

*(Runtime RE. Exclude specific variable from rule.)*

**Scenario:** The content of a POST body parameter named 'text_input' is causing false positives with rule 941150, "XSS Filter - Category 5: Disallowed HTML Attributes", at the specific location '/dynamic/new_post'. Removing this rule entirely is deemed to be unacceptable: the rule is not causing any other issues, and the protection it provides should be retained for everything apart from 'text_input' at the specific problematic location. It is decided to tune away this false positive by excluding 'text_input' from rule 941150 for location '/dynamic/new_post' only.

**Rule Exclusion:**

```apache
# CRS Rule Exclusion: 941150 - XSS Filter - Category 5: Disallowed HTML Attributes
SecRule REQUEST_URI "@beginsWith /dynamic/new_post" \
    "id:1020,\
    phase:1,\
    pass,\
    nolog,\
    ctl:ruleRemoveTargetById=941150;ARGS:text_input"
```

#### Example 8 *(ctl:ruleRemoveTargetByTag)*

*(Runtime RE. Exclude specific variable from rule.)*

**Scenario:** The values of request cookie 'uid' are causing false positives with various SQL injection rules when trying to log in to a web service at location '/webapp/login.html'. It is decided that it is not a risk to allow SQL-like content in this specific cookie's values for the login page, however it is deemed unacceptable to disable the SQLi detection rules for anything apart from the specific request cookie in question at the login page only. It is decided to tune away these false positives by excluding only the problematic request cookie from the SQLi detection rules, and only when accessing '/webapp/login.html'.

**Rule Exclusion:**

```apache
# CRS Rule Exclusion: Exclude the request cookie 'uid' from the SQLi detection rules
SecRule REQUEST_URI "@beginsWith /webapp/login.html" \
    "id:1030,\
    phase:1,\
    pass,\
    nolog,\
    ctl:ruleRemoveTargetByTag=attack-sqli;REQUEST_COOKIES:uid"
```

{{% notice tip %}}
It's possible to write a conditional rule exclusion that tests something other than just the request URI. Conditions can be built which test the source IP address, HTTP request method, HTTP headers, and even the day of the week.
{{% /notice %}}

#### Rule Exclusion Packages

TODO

## Further Reading

Detailed reference of each of the rule exclusion mechanisms outlined above can be found in the [ModSecurity Reference Manual](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)):

- Configure-time rule exclusion mechanisms:
  - [SecRuleRemoveById](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveById)
  - [SecRuleRemoveByTag](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveByTag)
  - [SecRuleUpdateTargetById](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleUpdateTargetById)
  - [SecRuleUpdateTargetByTag](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleUpdateTargetByTag)
- Runtime rule exclusion mechanisms:
  - [The ctl action](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#ctl)
