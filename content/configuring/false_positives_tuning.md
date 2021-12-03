---
title: "False Positives and Tuning"
chapter: false
weight: 18
---

> When a *genuine* transaction causes a rule form the Core Rule Set to match in error it is described as a **false positive**. False positives need to be tuned away by writing *rule exclusions*, as this page explains.

## What are False Positives?

The Core Rule Set provides _generic_ attack detection capabilities. A fresh CRS deployment has no awareness of the web services that may be running behind it, or the quirks of how those services work. It is possible that *genuine* transactions may cause some CRS rules to match in error, if the transactions happen to match one of the generic attack behaviors or patterns that are being detected. Such a match is referred to as a *false positive*, or false alarm.

False positives are particularly likely to happen when operating at higher [paranoia levels]({{< ref "paranoia_levels" >}} "Page describing paranoia levels."). While paranoia level 1 is designed to cause few, ideally zero, false positives, higher paranoia levels are increasingly likely to cause false positives. Each successive paranoia level introduces additional rules, with *higher* paranoia levels adding *more aggressive* rules. As such, the higher the paranoia level is the more likely it is that false positives will occur. That is the cost of the higher security provided by higher paranoia levels: the additional time it takes to tune away the increasing number of false positives.

### Example False Positive

Imagine deploying the CRS in front of a WordPress instance. The WordPress engine features the ability to add HTML to blog posts (as well as JavaScript, if you're an administrator). Internally, WordPress has rules controlling which HTML tags are allowed to be used. This list of allowed tags has been studied heavily by the security community and it's considered to be a secure mechanism.

Consider the CRS inspecting a request with a URL like the following:

```
www.example.com/?wp_post=<h1>Welcome+To+My+Blog</h1>
```

At paranoia level 2, the `wp_post` query string parameter would trigger a match against an XSS attack rule due to the presence of HTML tags. CRS is unaware that the problem is properly mitigated on the server side and, as a result, the request causes a false positive and may be blocked. The false positive may generate an error log line like the following:

```
[Wed Jan 01 00:00:00.123456 2022] [:error] [pid 2357:tid 140543564093184] [client 10.0.0.1:0] [client 10.0.0.1] ModSecurity: Warning. Pattern match "<(?:a|abbr|acronym|address|applet|area|audioscope|b|base|basefront|bdo|bgsound|big|blackface|blink|blockquote|body|bq|br|button|caption|center|cite|code|col|colgroup|comment|dd|del|dfn|dir|div|dl|dt|em|embed|fieldset|fn|font|form|frame|frameset|h1|head ..." at ARGS:wp_post. [file "/etc/crs/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf"] [line "783"] [id "941320"] [msg "Possible XSS Attack Detected - HTML Tag Handler"] [data "Matched Data: <h1> found within ARGS:wp_post: <h1>welcome to my blog</h1>"] [severity "CRITICAL"] [ver "OWASP_CRS/3.3.2"] [tag "application-multi"] [tag "language-multi"] [tag "platform-multi"] [tag "attack-xss"] [tag "OWASP_CRS"] [tag "capec/1000/152/242/63"] [tag "PCI/6.5.1"] [tag "paranoia-level/2"] [hostname "www.example.com"] [uri "/"] [unique_id "Yad-7q03dV56xYsnGhYJlQAAAAA"]
```

This example log entry provides lots of information about the rule match. Some of the key pieces of information are:

- The message from ModSecurity, which explains what happened and where:

  `ModSecurity: Warning. Pattern match "<(?:a|abbr|acronym ..." at ARGS:wp_post.`

- The rule ID of the matched rule:

  `[id "941320"]`

- The additional matching data from the rule, which explains precisely what caused the rule match:

  `[data "Matched Data: <h1> found within ARGS:wp_post: <h1>welcome to my blog</h1>"]`

{{% notice tip %}}
CRS ships with a prebuilt *rule exclusion package* for WordPress, as well as other popular web applications, to help prevent false positives. See the section on [rule exclusion packages]({{< ref "#rule-exclusion-packages" >}}) for details. 
{{% /notice %}}

### Why are False Positives a Problem?

#### Alert Fatigue

If a system is prone to reporting false positives then the alerts it raises may be ignored. This may lead to real attacks being overlooked. For this reason, leaving false positives mixed in with real attacks is dangerous: the false positives should be resolved.

#### Sensitive Information and Regulatory Compliance

A false positive alert may contain sensitive information, for example usernames, passwords, and payment card data. Imagine a situation where a web application user has set their password to '/bin/bash': without proper tuning, this input would cause a false positive every time the user logged in, writing the user's password to the error log file in plaintext as part of the alert.

It's also important to consider issues surrounding regulatory compliance. Data protection and privacy laws, like GDPR and CCPA, place strict duties and limitations on what information can be gathered and how that information is processed and stored. The unnecessary logging data generated by false positives can cause problems in this regard.

#### Poor User Experience

When working in strict blocking mode, false positives can cause legitimate user transactions to be blocked, leading to poor user experience. This can create pressure to disable the CRS or even to remove the WAF solution entirely, which is an unnecessary sacrifice of security for usability. The correct solution to this problem is to tune away the false positives so that they don't reoccur in the future.

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
Runtime rule exclusions, while granular and flexible, have a computational overhead, albeit a small one. A runtime rule exclusion is an extra SecRule which must be evaluated for every transaction.
{{% /notice %}}

In addition to the two *types* of exclusions, rules can be excluded in two different *ways*:

- **Exclude the entire rule:** An entire rule is removed and will not be executed by the rule engine.
- **Exclude a specific variable from the rule:** A *specific variable* will be excluded from a specific rule.

These two methods can also operate on multiple rules or even entire rule categories.

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

As well as rules being tagged using different categories, CRS rules are organized into files by general category. In addition, CRS rule IDs follow a consistent numbering convention. This makes it easy to remove unwanted types of rules by removing ranges of rule IDs. For example, the file `REQUEST-933-APPLICATION-ATTACK-PHP.conf` contains the PHP related rules, which all have rule IDs in the range 933000-933999. All of the rules in this file can be easily removed using a configure-time rule exclusion, like so:

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
It's possible to write a conditional rule exclusion that tests something other than just the request URI. Conditions can be built which test, for example, the source IP address, HTTP request method, HTTP headers, and even the day of the week.
{{% /notice %}}

#### Rule Exclusion Packages

CRS ships with prebuilt *rule exclusion packages* for a selection of popular web applications. These packages contain application-specific rule exclusions designed to prevent false positives from occurring when CRS is put in front of one of these web applications.

The packages should be viewed as a good *starting point* from which to build upon. Some false positives may still occur, for example if working at a high paranoia level, if using a very new or old version of the application, if using plug-ins, add-ons, or user customisations.

If using a native Core Rule Set installation, rule exclusion packages can be enabled in the file `crs-setup.conf`. Modify rule 900130 to select the web applications in question, e.g. to enable the DokuWiki rule exclusion package use `setvar:tx.crs_exclusions_dokuwiki=1`, and then uncomment the rule to enable it.

If running CRS where it has been integrated into a commercial product or CDN then support varies. Some vendors expose rule exclusion packages in the GUI while other vendors require custom rules to be written which set the necessary variables. Unfortunately, there are also vendors that don't allow rule exclusion packages to be used at all.

{{% notice tip %}}
If running multiple web applications, it is highly recommended to enable a rule exclusion package only for the location where the corresponding web application resides. For example, to enable the WordPress rule exclusion package only for locations under '/wordpress', a rule like the following could be used:

```apache
SecRule REQUEST_URI "@beginsWith /wordpress/" setvar:tx.crs_exclusions_wordpress=1...
```
{{% /notice %}}

Rule exclusion packages are currently available for the following web applications:

- [cPanel](https://cpanel.net)
- [DokuWiki](https://www.dokuwiki.org)
- [Drupal](https://www.drupal.org)
- [Nextcloud](https://nextcloud.com)
- [phpBB](https://www.phpbb.com)
- [phpMyAdmin](https://www.phpmyadmin.net)
- [WordPress](https://wordpress.org)
- [XenForo](https://xenforo.com)

The CRS project is always looking to work with other communities and individuals to add support for additional web applications. Please get in touch via [GitHub](https://github.com/coreruleset/coreruleset) to discuss writing a rule exclusion package for a specific web application.

## Further Reading

 A popular tutorial titled [Handling False Positives with the OWASP ModSecurity Core Rule Set](https://www.netnea.com/cms/apache-tutorial-8_handling-false-positives-modsecurity-core-rule-set/) by Christian Folini walks through a full CRS tuning process, with examples.

Detailed reference of each of the rule exclusion mechanisms outlined above can be found in the [ModSecurity Reference Manual](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)):

- Configure-time rule exclusion mechanisms:
  - [SecRuleRemoveById](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveById)
  - [SecRuleRemoveByTag](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleRemoveByTag)
  - [SecRuleUpdateTargetById](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleUpdateTargetById)
  - [SecRuleUpdateTargetByTag](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleUpdateTargetByTag)
- Runtime rule exclusion mechanisms:
  - [The ctl action](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#ctl)
