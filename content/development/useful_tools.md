---
title: "Useful Tools"
#menuTitle: ""
chapter: false
weight: 6
---

> There are many third party tools that help with ModSecurity and CRS development. The most useful ones are listed here. Get in touch if you think something is missing.

## FTW

https://pypi.org/project/ftw/

*Framework for Testing WAFs.* The original Python-based testing framework used by CRS.

## Go-FTW

https://github.com/fzipi/go-ftw

*Framework for Testing WAFs in Go.* A Go-based rewrite of the original Python FTW project. Usually much faster than the original and has no dependencies.

## Official CRS Maintained Docker Images

### ModSecurity Core Rule Set Docker Image

https://github.com/coreruleset/modsecurity-crs-docker

A Docker image supporting the latest stable CRS release on: 

- the latest stable ModSecurity v2 on Apache
- the latest stable ModSecurity v3 on Nginx

### ModSecurity Docker Image

https://github.com/coreruleset/modsecurity-docker

A Docker image supporting:

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
