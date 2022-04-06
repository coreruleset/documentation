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
4. Signed commits are preferred. (For more information and help with this, refer to the [GitHub documentation](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)).

## Making Changes

* Base any changes on the latest dev branch (e.g. `{{< param crs_dev_branch >}}`).
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

* Use the following character class, in the stated order, to cover alphanumeric characters plus underscores and hyphens: `[a-zA-Z0-9_-]`

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

TODO

### Lazy Matching

TODO

### Writing RE2-compatible Regular Expressions

Avoid "lookbehind" and "lookafter".

TODO

## Rules Compliance with Paranoia Levels

The rules in CRS are organized into **paranoia levels** (PLs) which makes it possible to define how aggressive CRS is. See the documentation on [paranoia levels](https://coreruleset.org/docs/configuring/paranoia_levels/) for an introduction and more detailed explanation.

The types of rules that are allowed at each paranoia level are as follows:

**PL 0:**

* ModSecurity / WAF engine installed, but almost no rules

**PL 1:**

* Default level: keep in mind that most installations will normally use this level
* Any complex, memory consuming evaluation rules will surely belong to a higher level, not this one
* CRS will normally use atomic checks in single rules at this level
* Confirmed matches only; all scores are allowed
* No false positives / low false positives: try to avoid adding rules with potential false positives!
* False negatives could happen

**PL 2:**

* [Chain](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual(v2.x)#chain) usage is allowed
* Confirmed matches use score critical
* Matches that cause false positives are limited to using scores notice or warning
* Low false positive rates
* False negatives are not desirable

**PL 3:**

* Chain usage with complex regular expression look arounds and macro expansions are allowed
* Confirmed matches use scores warning or critical
* Matches that cause false positives are limited to using score notice
* False positive rates are higher but limited to multiple matches (not single strings)
* False negatives should be a very unlikely accident

**PL 4:**

* Every item is inspected
* Variable creations are allowed to avoid engine limitations
* Confirmed matches use scores notice, warning, or critical
* Matches that cause false positives are limited to using scores notice or warning
* False positive rates are higher (even on single strings)
* False negatives should not happen at this level
* Check everything against RFCs and allow listed values for the most popular elements

## ID Numbering Scheme

The CRS project uses the numerical ID rule namespace from 900,000 to 999,999 for CRS rules, as well as 9,000,000 to 9,999,999 for default CRS rule exclusion packages and plugins.

- Rules applying to the **incoming request** use the ID range 900,000 to 949,999.
- Rules applying to the **outgoing response** use the ID range 950,000 to 999,999.

The rules are grouped by the vulnerability class they address (SQLi, RCE, etc.) or the functionality they provide (e.g. initialization). These groups occupy blocks of thousands (e.g. SQLi: 942,000 - 942,999). These grouped rules are defined in files dedicated to a single group or functionality. The filename takes up the first three digits of the rule IDs defined within the file (e.g. SQLi: `REQUEST-942-APPLICATION-ATTACK-SQLI.conf`).

The individual rules within each file for a vulnerability class are organized by the paranoia level of the rules. PL 1 is first, then PL 2, etc.

The ID block 9xx000 - 9xx099 is reserved for use by CRS helper functionality. There are no blocking or filtering rules in this block.

Among the rules providing CRS helper functionality are rules that skip other rules depending on the paranoia level. These rules always use the following reserved rule IDs: 9xx011 - 9xx018, with very few exceptions.

The blocking and filter rules start at 9xx100 with a step width of 10, e.g. 9xx100, 9xx110, 9xx120, etc.

The ID of a rule does not correspond directly with its paranoia level. Given the size of rule groups and how they're organized by paranoia level (starting with the lower PL rules first), PL 2 and above tend to be composed of rules with higher ID numbers.

### Stricter Siblings

Within a rule file / block, there are sometimes smaller groups of rules that belong together. They're closely linked and very often represent copies of the original rules with a stricter limit (alternatively, they can represent the same rule addressing a different *target* in a second rule, where this is necessary). These are **stricter siblings** of the base rule. Stricter siblings usually share the first five digits of the rule ID and raise the rule ID by one, e.g. a base rule at 9xx160 and a stricter sibling at 9xx161.

Stricter siblings often have different paranoia levels. This means that the base rule and the stricter siblings don't usually reside next to each another in the rule file. Instead, they're ordered by paranoia level and are linked by the first digits of their rule IDs. It's good practice to introduce all stricter siblings together as part of the definition of the base rule: this can be done in the comments of the base rule. It's also good practice to refer back to the base rule with the keywords "stricter sibling" in the comments of the stricter siblings themselves. For example: "...This is performed in two separate stricter siblings of this rule: 9xxxx1 and 9xxxx2", and "This is a stricter sibling of rule 9xxxx0."

## Non-Rules General Guidelines

* Remove trailing spaces from files (if they're not needed). This will make linters happy.
* EOF should have an EOL.

The `pre-commit` framework can be used to check for and fix these issues automatically. First, go to the [pre-commit](https://pre-commit.com/) website and download the framework. Then, after installing, use the command `pre-commit install` so that the tools are installed and run each time a commit is made. CRS provides a config file that will keep the repository clean.
