---
title: Useful Tools
weight: 66
disableToc: false
chapter: false
aliases: ["../development/useful_tools"]
---

> There are many first and third party tools that help with ModSecurity and CRS development. The most useful ones are listed here. Get in touch if you think something is missing.

## albedo

https://github.com/coreruleset/albedo

The backend server used by the CRS test suite. It is especially useful for testing response rules, as desired responses can be freely specified.

## coraza-httpbin

https://github.com/jcchavezs/coraza-httpbin

A Coraza plus reverse proxy container for testing. Makes it possible to easily test CRS with Coraza in a similar way to testing CRS using the Apache and Nginx Docker containers.

A local CRS installation can be included using directives in a `directives.conf` file like so:

```
Include ../coreruleset/crs-setup.conf.example
Include ../coreruleset/rules/*.conf
```

## crs-toolchain

https://github.com/coreruleset/crs-toolchain

The CRS developer's toolbelt. Documentation lives at [crs-toolchain]({{< ref "6-2-crs-toolchain.md" >}}).

## Go-FTW

https://github.com/coreruleset/go-ftw

*Framework for Testing WAFs in Go.* A Go-based rewrite of the original Python FTW project.

## Official CRS Maintained Docker Images

### ModSecurity CRS Docker Image

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

## CrsDoc

https://crsdoc.digitalwave.hu

Presents CRS rules using a structured UI, allowing for filtering and searching.

## Syntax Highlighters

### Regex Assembly

We have a syntax highlighting extension for Visual Studio Code that helps with writing assembly files. Instructions on how to install the extension can be found in the readme of the repository: https://github.com/coreruleset/regexp-assemble-syntax.

### ModSecurity SecLang

A community member has created an experimental syntax highlighter extension for the ModSecurity SecLang for Visual Studio Code. It has a nice documentation feature for syntax elements and variables. Both highlighting and documentation have been generated using GPT-5, so expect some issues and inaccuracies. https://github.com/louis-lau/vscode-secrule-language-plugin.