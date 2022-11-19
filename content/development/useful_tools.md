---
title: Useful Tools
weight: 30
disableToc: false
chapter: false
---

> There are many first and third party tools that help with ModSecurity and CRS development. The most useful ones are listed here. Get in touch if you think something is missing.

## crs-toolchain

https://github.com/coreruleset/crs-toolchain

The CRS developer's toolbelt. Documentation lives at [crs-toolchain]({{< ref "crs_toolchain" >}}).

## Go-FTW

https://github.com/coreruleset/go-ftw

*Framework for Testing WAFs in Go.* A Go-based rewrite of the original Python FTW project.

## Official CRS Maintained Docker Images

### ModSecurity Core Rule Set Docker Image

https://github.com/coreruleset/modsecurity-crs-docker

A Docker image supporting the latest stable CRS release on: 

- the latest stable ModSecurity v2 on Apache
- the latest stable ModSecurity v3 on Nginx

## msc_pyparser

https://github.com/digitalwave/msc_pyparser

A ModSecurity config parser. Makes it possible to modify SecRules en masse, for example adding a tag to every rule in a rule set simultaneously.

## msc_retest (RE test)

https://github.com/digitalwave/msc_retest

An invaluable tool for testing how regular expressions behave *and perform* in both `mod_security2` (the Apache module) and `libModSecurity` (ModSecurity v3).

## Regexploit

https://github.com/doyensec/regexploit

A tool for testing and finding regular expressions that are vulnerable to regular expression denial of service attacks ([ReDoS](https://en.wikipedia.org/wiki/ReDoS)).
