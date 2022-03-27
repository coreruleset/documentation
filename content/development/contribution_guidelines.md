---
title: "Contribution Guidelines"
#menuTitle: ""
chapter: false
weight: 5
---

> The CRS project values third party contributions. To make the contribution process as easy as possible, a helpful set of contribution guidelines are in place which all contributors and developers are asked to adhere to.

## Getting Started with a New Contribution

1. Sign in to [GitHub](https://github.com/join).
2. Open a [new issue](https://github.com/coreruleset/coreruleset/issues) for the contribution, *assuming a similar issue doesn't already exist*.
    * **Clearly describe the issue**, including steps to reproduce if reporting a bug.
    * **Specify the CRS version in question** if reporting a bug.
    * Bonus points for submitting tests along with the issue.
3. Fork the repository on GitHub and begin making changes there.

## Making Changes

* Base any changes on the latest dev branch (e.g. `v3.4/dev`).
* Create a topic branch for each new contribution.
* Fix only one problem at a time. This helps to quickly test and merge submitted changes. If intending to fix *multiple unrelated problems* then use a separate branch for each problem.
* Make commits of logical units.
* Make sure commits adhere to the contribution guidelines presented in this document.
* Make sure commit messages follow the [standard Git format](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

## General Formatting Guidelines for Rules Contributions

* American English should be used throughout.
* 4 spaces should be used for indentation (no tabs).
* No trailing whitespace at EOL.
* No trailing blank lines at EOF.
* Add comments where possible and clearly explain any new rules.
* Adhere to an 80 character line length limit where possible.
* All [chained rules](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual(v2.x)#chain) should be indented like so, for readability:
```
SecRule .. .. \
    "..."
    SecRule .. .. \
        "..."
        SecRule .. .. \
            "..."
```
- Action lists in rules must always be enclosed in double quotes for readability, even if there is only one action (e.g. use `"chain"` instead of `chain`, and `"ctl:requestBodyAccess=Off"` instead of `ctl:requestBodyAccess=Off`).
- Always use numbers for phases instead of names.
- Format all use of `SecMarker` using double quotes, using UPPERCASE, and separating words with hyphens. For example:
```
SecMarker "END-RESPONSE-959-BLOCKING-EVALUATION"
SecMarker "END-REQUEST-910-IP-REPUTATION"
```
- Rule actions should appear in the following order, for consistency:
```
id
phase
allow | block | deny | drop | pass | proxy | redirect
status
capture
t:xxx
log
nolog
auditlog
noauditlog
msg
logdata
tag
sanitiseArg
sanitiseRequestHeader
sanitiseMatched
sanitiseMatchedBytes
ctl
ver
severity
multiMatch
initcol
setenv
setvar
expirevar
chain
skip
skipAfter
```

## Variable Naming Conventions

* Variable names should be lowercase and should use the characters a-z, 0-9, and underscores only.
* To reflect the different syntax between *defining* a variable (using `setvar`) and *using* a variable, the following visual distinction should be applied:
    * **Variable definition:** Lowercase letters for collection name, dot as the separator, variable name. E.g.: `setvar:tx.foo_bar_variable`
    * **Variable use:** Capital letters for collection name, colon as the separator, variable name. E.g.: `SecRule TX:foo_bar_variable`

## Writing Regular Expressions

* The preferred style: `[a-zA-Z0-9_-]`

### Portable Backslash Representation

CRS uses `\x5c` to represent the backslash `\` character in regular expressions. Some of the reasons for this are:

* It's portable across web servers and WAF engines: it works with Apache, Nginx, and Coraza.
* It works with the `regexp-assemble.py` script for building optimized regular expressions.

The older style of representing a backslash using the character class `[\\\\]` must _not_ be used. This was previously used in CRS to get consistent results between Apache and Nginx, owing to a quirk with how Apache would "double un-escape" character escapes. For future reference, the decision was made to stop using this older method because:

* It can be confusing and difficult to understand how it works.
* It doesn't work with the `regexp-assemble.py` script.
* It doesn't work with Coraza.
* It isn't obvious how to use it in a character class, e.g. `[a-zA-Z<portable-backslash>]`.

### When and Why to Anchor Regular Expressions

### Lazy Matching

### Writing RE2-compatible Regular Expressions

Avoid "lookbehind" and "lookafter".

## Rules Compliance with each Paranoia Level (PL)

Rules in the CRS are organized in Paranoia Levels, which allows you to choose the desired level of rule checks.

Please read file ```crs-setup.conf.example``` for an introduction and a more detailed explanation of Paranoia Levels in the section `# -- [[ Paranoia Level Initialization ]]`.

**PL0:**

* Modsec installed, but almost no rules

**PL1:**

* Default level, keep in mind that most installations will normally use this one
* If there is a complex memory consuming/evaluation rule it surely will be on upper levels, not this one
* Normally we will use atomic checks in single rules
* Confirmed matches only, all scores are allowed
* No false positives / Low FP (Try to avoid adding rules with potential false positives!)
* False negatives could happen

**PL2:**

* Chains usage are OK
* Confirmed matches use score critical
* Matches that cause false positives are limited to use score notice or warning
* Low False positive rates
* False negatives are not desirable

**PL3:**

* Chains usage with complex regex look arounds and macro expansions
* Confirmed matches use score warning or critical
* Matches that cause false positives are limited to use score notice
* False positive rates increased but limited to multiple matches (not single string)
* False negatives should be a very unlikely accident

**PL4:**

* Every item is inspected
* Variable creations allowed to avoid engine limitations
* Confirmed matches use score notice, warning or critical
* Matches that cause false positives are limited to use score notice and warning
* False positive rates increased (even on single string)
* False negatives should not happen here
* Check everything against RFC and allow listed values for most popular elements


## ID Numbering Scheme

The CRS project used the numerical id rule namespace from 900,000 to 999,999 for the CRS rules as well as 9,000,000 to 9,999,999 for default CRS rule exclusion packages.

Rules applying to the incoming request use the id range 900,000 to 949,999.
Rules applying to the outgoing response use the id range 950,000 to 999,999.

The rules are grouped by vulnerability class they address (SQLi, RCE, etc.) or functionality (initialization). These groups occupy blocks of thousands (e.g. SQLi: 942,000 - 942,999).
The grouped rules are defined in files dedicated to a single group or functionality. The filename takes up the first three digits of the rule ids defined within the file (e.g. SQLi: REQUEST-942-APPLICATION-ATTACK-SQLI.conf).

The individual rule files for the vulnerability classes are organized by the paranoia level of the rules. PL 1 is first, then PL 2 etc.

The block from 9XX000 - 9XX099 is reserved for use by CRS helper functionality. There are no blocking or filtering rules in this block.

Among the rules serving a CRS helper functionality are rules that skip rules depending on the paranoia level. These rules always use the following reserved rule ids: 9XX011-9XX018 with very few exceptions.

The blocking or filter rules start with 9XX100 with a step width of 10. E.g. 9XX100, 9XX110, 9XX120 etc. The rule id does not correspond directly with the paranoia level of a rule. Given the size of a rule group and the organization by lower PL rules first, PL2 and above tend to have rule IDs with higher numbers.

Within a rule file / block, there are sometimes smaller groups of rules that belong to together. They are closely linked and very often represent copies of the original rules with a stricter limit (alternatively, they can represent the same rule addressing a different target in a second rule where this was necessary). These are stricter siblings of the base rule. Stricter siblings usually share the first five digits of the rule ID and raise the rule ID by one. E.g., Base rule at 9XX160, stricter sibling at 9XX161.

Stricter siblings often have a different paranoia level. This means that the base rule and the stricter sibling do not reside next to one another in the rule file. Instead they are ordered in their appropriate paranoia level and can be linked via the first digits of the rule id. It is a good practice to introduce stricter siblings together with the base rule in the comments of the base rule and to reference the base rule with the keyword stricter sibling in the comments of the stricter sibling. E.g., "... This is
performed in two separate stricter siblings of this rule: 9XXXX1 and 9XXXX2", "This is a stricter sibling of rule 9XXXX0."

## Non-rules General Guidelines

* Remove trailing spaces from files (if they are not needed). This will make linters happy.
* EOF should have an EOL

You can use `pre-commit` to fix those automatically. Just go to the [pre-commit](https://pre-commit.com/) website and download it. After installing, use `pre-commit install` so the tools are installed and run each time you want to commit. We provide you with the config file that will keep our repo clean.
