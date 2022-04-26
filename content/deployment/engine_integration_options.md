---
title: "Engine and Integration Options"
menuTitle: "Engine and Integration Options"
chapter: false
weight: 5
---

> The Core Rule Set runs on a WAF engine that is compatible with a subset of ModSecurity's SecLang configuration language. There are several options outside of ModSecurity itself, namely via cloud offerings and Content Delivery Network (CDN) services. But there is also a open source alternative to ModSecurity in the form of the new Coraza WAF engine.

## Compatible WAF Engines

### ModSecurity v2

ModSecurity v2, originally a security module for the Apache web server, is the reference implementation for CRS.

ModSecurity 2.9.x passes 100% of our unit tests on the Apache platform.

When running ModSecurity yourself, this is the option that is guaranteed to work with a lot of documentation and know-how all around.

ModSecurity is released under an Apache 2 license. However, it is primarily developed by Spiderlabs, an entity within the company Trustwave. In Summer 2021, Trustwave announced it will end development of ModSecurity in 2024. Attempts to convince Trustwave to hand over the project in the meantime to guarantee continuation failed. Trustwave replied they will not let go before 2024.

As of this writing, there is no imminent need to leave the ModSecurity v2 platform, but such a step may become necessary as development stalls or new security problems can no longer be fixed. Yet the CRS community is confident it has the power and knowledge to provide ModSecurity patches if really needed.

If you want to learn more about the situation around ModSecurity, then [read this blog post](https://coreruleset.org/20211222/talking-about-modsecurity-and-the-new-coraza-waf/)

There is a [ModSecurity v2 / Apache Docker container](https://github.com/coreruleset/modsecurity-crs-docker) maintained by the CRS project.

### ModSecurity v3

ModSecurity v3 - also known as libModSecurity - is a re-implementation of ModSecurity v3 with an architecture that is less dependent on the webserver. The connection between the standalone ModSecurity and the webserver is performed via a lean connector module.

As of Spring 2021, only the NGINX connector module is really usable in production.

ModSecurity v3 fails with 2-4% of the CRS unit tests due to bugs and implementation gaps and NGINX + ModSecurity v3 also suffers from performance problems when compared to the Apache + ModSecurity v2 platform. This may be surprising for people familiar with the high performance of NGINX.

ModSecurity v3 is used in production together with NGINX, yet the CRS project recommends to go with the ModSecurity v2 release line.

ModSecurity is released under an Apache 2 license. However, it is primarily developed by Spiderlabs, an entity within the company Trustwave. In Summer 2021, Trustwave announced it will end development of ModSecurity in 2024. Attempts to convince Trustwave to hand over the project in the meantime to guarantee continuation failed. Trustwave replied they will not let go before 2024.

If you want to learn more about the situation around ModSecurity, then [read this blog post](https://coreruleset.org/20211222/talking-about-modsecurity-and-the-new-coraza-waf/)

There is a [ModSecurity v3 / NGINX Docker container](https://github.com/coreruleset/modsecurity-crs-docker) maintained by the CRS project.

### Coraza WAF Engine

The new [OWASP Coraza WAF](https://coraza.io/) is meant to bring an open source alternative for the two ModSecurity release lines.

Coraza passes 100% of the CRS v4 test suite and is thus fully compatible with CRS.

Coraza has been developed in GO and currently runs on the Caddy and Traefik platforms. Additional ports are being developed and the developers also seek to bring Coraza to NGINX and eventually to Apache. In parallel to this expansion, Coraza will be developed further with its own feature set.

If you want to learn more about CRS and Coraza, then [read this blog post](https://coreruleset.org/20211222/talking-about-modsecurity-and-the-new-coraza-waf/)

### Commercial WAF appliances

Dozens of commercial WAFs - virtual and hardware based - offer CRS as part of their service. Many of them use ModSecurity underneath or some alternative implementation (yet this is rare on the WAF appliance approach). Most of these commercial WAFs do not offer the full feature set of CRS or they do not make it easily accessible. With some of these companies, there is also a lack of CRS experience and know-ledge.

We recommend evaluating the offerings in a holistic way before buying a license.

In light of the many, many appliance offerings on the market and our limited exposure, we are only listing one or two of them.

### Kemp / Progressive LoadMaster

The Kemp LoadMaster is a popular load balancer that integrates ModSecurity v2 and CRS in a typical way. It goes further than the competition with the support of most CRS features.

Learn more about [CRS on Loadmaster here](https://kemptechnologies.com/blog/how-to-run-owasp-open-web-application-security-project-i-kemp-load-master/)

Kemp / Progressive is a sponsor of CRS.

### Loadbalancer.org

The Loadbalancer.org is a loadbalancer based on Apache and ModSecurity v2. We've seen several successful deployments of this appliance, namly on Azure.

[Learn more about this](https://www.loadbalancer.org/blog/how-to-train-your-waf/)


## Existing CRS Integrations: Cloud and CDN Offerings

Most big Cloud providers and CDNs have a CRS offering these days. While originally being based on ModSecurity, the have meanwhile all moved to alternative implementation of ModSecurity's SecLang configuration language or they transpose the CRS rules written in SecLang into their own Domain Specific Language (DSL).

We have some insight into some of these platforms and we are in touch with most of these offerings. But we do not really know all the specifics. We do know however, that almost all of these integrators compromised on a subset of CRS rules and a subset of features for ease of integration and operation.

{{% notice info %}}
The [CRS Status page project](https://github.com/coreruleset/coreruleset/wiki/DevRetreat21StatusPage) will be testing cloud and CDN offerings. As part of this effort, we will be documenting results and even publishing code on how to quickly get started using CRS in CDN/cloud providers. This status page project is in development as of Spring 2022.
{{% /notice %}}

Below, we list a selection of these platforms with links to get more infos.

### AWS WAF

AWS provides an [abridged version of the Core Rule set](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html). It's confusing initially because, as a managed rule set, it's called `AWSManagedRulesCommonRuleSet`, but technically it's their partial implementation of / resembles the CRS.

### Cloudflare WAF

Cloudflare WAF supports CRS as one of its WAF rule sets. Documentation on how to use it can be found [here](https://developers.cloudflare.com/waf/managed-rulesets/owasp-core-ruleset/).


### Edgecast

Edgecast offers CRS as a managed rule set as part of their WAF service that runs on a ModSecurity re-implementation called WAFLZ.

If you want to learn more about Edgecast, then [check out his document](https://docs.edgecast.com/cdn/Content/Web-Security/Managed-Rules.htm#RuleSet).

### Fastly

Fastly has been offering CRS as part of their Fastly WAF for several years, but started to migrate their existing customers to the recently acquired Signal Sciences WAF. Interestingly, Fastly is transposing CRS rules into their own varnish-based WAF engine.

Here is more information about the [Fastly CRS offering](https://docs.fastly.com/en/guides/fastly-waf-rule-set-updates-maintenance-legacy).

### Google Cloud Armor

Google integrates CRS into its Cloud Armor WAF offering. It runs the CRS rules on their own WAF engine. As of Spring 2021, Google only offers an outdated version of CRS.

If you want to learn more about CRS on Google's Cloud Armor, then [see this document](https://cloud.google.com/armor/docs/rule-tuning)

Google Cloud Armor is a sponsor of CRS.

### Microsoft Azure WAF

Azure Application Gateways can be configured to use the WAFv2 and [managed rules with different versions of CRS](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules). Azure provides the 3.2, 3.1, 3.0, and 2.2.9 CRS versions. **We recommend using version 3.2** (see our [security policy](https://github.com/coreruleset/coreruleset/blob/v3.4/dev/SECURITY.md) for details on supported CRS versions).

### Oracle WAF

The Oracle WAF is a cloud based offering that includes CRS. See [here](https://docs.oracle.com/en-us/iaas/Content/WAF/Concepts/waftuning.htm) for more infos.

## Alternative Use Cases

Outside of the narrower implementation of a WAF, CRS can also be found in different security-related setups.

### Sqreen / Datadog

Sqreen uses a subset of CRS as an innovative part of their RASP offering. Here are [some tidbits](https://blog.sqreen.com/sqreen-october-release/) about this offering.
