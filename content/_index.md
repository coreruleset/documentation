---
title: "CRS Documentation"
description: "CRS Documentation"
---

> OWASP CRS provides documentation for many of the aspects surrounding the project. This page provides an overview of the project and its documentation.

{{% notice info %}}
Security issues regarding CRS can be submitted via email to security [ at ] coreruleset.org.
{{% /notice %}}

## What is CRS?

OWASP® (Open Worldwide Application Security Project) CRS (previously Core Rule Set) is a free and open-source collection of rules that work with ModSecurity® and compatible web application firewalls (WAFs). These rules are designed to provide easy to use, generic attack detection capabilities, with a minimum of false positives (false alerts), to web applications as part of a well balanced defense-in-depth solution.

## How to Get Involved

For information on how to join the vibrant community of CRS developers, start by checking out the project's [GitHub repository](https://github.com/coreruleset/coreruleset). When ready to make a contribution, have a read of the project's [contribution guidelines]({{% ref "development/contribution_guidelines/" %}}) which are used to keep the project consistent, well managed, and of a high quality.

## CRS Change Policy

The project endeavors not to make breaking changes in **minor releases** (i.e., 3.3.2). Instead, these releases fix bugs identified in the previous release.

New functionality and breaking changes are made in **major releases** (i.e., 3.3).

For information about what has changed in recent versions of the software, refer to the project's [CHANGES](https://github.com/coreruleset/coreruleset/blob/main/CHANGES.md) file on GitHub.

## Documentation Source

The source files for this documentation can be found at the [CRS documentation repository](https://github.com/coreruleset/documentation) on GitHub.

This documentation has been statically generated with [Hugo](https://github.com/gohugoio/hugo). It uses the [Hugo Relearn Theme](https://github.com/McShelby/hugo-theme-relearn).

## License

OWASP CRS is a free and open-source set of security rules which use the Apache License 2.0. Although it was originally developed for ModSecurity's SecRules language, the rule set can be, and often has been, freely modified, reproduced, and adapted for various commercial and non-commercial endeavors. The CRS project encourages individuals and organizations to contribute back to the OWASP CRS where possible.
