---
title: "OWASP Core Rule Set Documentation"
---

# Core Rule Set Project

The OWASP Core Rule Set provides guidelines for many of the aspects surrounding the project. Please explore some of these below.

If you are looking to submit a security issue with the Core Rule Set please email security [ at ] coreruleset.org.

## Core Rule Set Documentation

### What is the Core Rule Set?

The OWASP® (Open Web Application Security Project) CRS (Core Rule Set) is an open source collection of rules that work with ModSecurity® and compatible web application firewalls (WAFs). These rules are designed to provide easy to use, generic attack detection capabilities, with a minimum of false positives (false alerts), to your web application as part of a well balanced defense-in-depth solution.

### Contribution Guidelines

If you are looking for information about how to join our vibrant community of Core Rule Set developers, we invite you to check out [our GitHub repository](https://github.com/coreruleset/coreruleset). When you’re ready to contribute, we've outlined some of the guidelines that we use to keep our project managed.

### Change Policy

The Core Rule Set project endeavors not to make breaking changes in minor releases (i.e. 3.1.1). Instead, these releases will fix bugs otherwise identified in the previous release. New functionality and breaking changes will be made in major releases (i.e. 3.3).

If you are interested in seeing what has changed in recent versions of the software please see our [CHANGES](https://github.com/coreruleset/coreruleset/blob/v3.4/dev/CHANGES) file.

### License

The OWASP Core Rule Set is a free and open-source set of security rules using the Apache License 2.0. Although it was originally developed for ModSecurity's SecRules language, the rule set can be, and often has been, freely modified, reproduced, and adapted for various commercial and non-commercial endeavors. We encourage individuals and organizations to commit back to the OWASP Core Rule Set where possible.

### Documentation Source

The source files for this documentation can be found at [our documentation repository on GitHub](https://github.com/coreruleset/documentation).

This documentation has been statically generated with [Hugo](https://github.com/gohugoio/hugo) with a simple command : `hugo`. The Hugo Relearn Theme is also used, the source code for which is [available here at GitHub](https://github.com/McShelby/hugo-theme-relearn).
