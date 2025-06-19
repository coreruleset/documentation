---
title: Engine and Integration Options
weight: 14
disableToc: false
chapter: false
aliases: ["../deployment/engine_integration_options"]
---

> CRS runs on WAF engines that are compatible with a subset of ModSecurity's SecLang configuration language. There are several options outside of ModSecurity itself, namely cloud offerings and content delivery network (CDN) services. There is also an open-source alternative to ModSecurity in the form of the new Coraza WAF engine.

## Compatible Free and Open-Source WAF Engines

### ModSecurity v2

ModSecurity v2, originally a security module for the Apache web server, is **the reference implementation for CRS**.

ModSecurity 2.9.x passes 100% of the CRS unit tests on the Apache platform.

When running ModSecurity, this is the option that is *practically guaranteed* to work with most documentation and know-how all around.

[ModSecurity](https://www.modsecurity.org) is released under the Apache License 2.0, and the project now lives under the OWASP Foundation umbrella.

There is a [ModSecurity v2 / Apache Docker container](https://github.com/coreruleset/modsecurity-crs-docker) which is maintained by the CRS project.

### ModSecurity v3

ModSecurity v3, also known as *libModSecurity*, is a re-implementation of ModSecurity v3 with an architecture that is less dependent on the web server. The connection between the standalone ModSecurity and the web server is made using a lean connector module.

As of spring 2021, *only the Nginx connector module is really usable in production*.

ModSecurity v3 fails with 2-4% of the CRS unit tests due to bugs and implementation gaps. Nginx + ModSecurity v3 also suffers from performance problems when compared to the Apache + ModSecurity v2 platform. This may be surprising for people familiar with the high performance of Nginx.

ModSecurity v3 is used in production together with Nginx, but the CRS project recommends to use the ModSecurity v2 release line with Apache.

ModSecurity is released under the Apache License 2.0. It is primarily developed by Spiderlabs, an entity within the company Trustwave. In summer 2021, Trustwave announced their plans to end development of ModSecurity in 2024. Since Jan 25th 2024, the project [transitioned to the OWASP Foundation](https://coreruleset.org/20240115/welcome-the-newest-addition-to-the-owasp-family-modsecurity/).

There is a [ModSecurity v3 / Nginx Docker container](https://github.com/coreruleset/modsecurity-crs-docker) which is maintained by the CRS project.

### Coraza

[OWASP Coraza WAF](https://coraza.io/) is meant to provide an open-source alternative to the two ModSecurity release lines.

Coraza passes 100% of the CRS v4 test suite and is thus *fully compatible with CRS*.

Coraza has been developed in Go and currently runs on the Caddy and Traefik platforms. Additional ports are being developed and the developers also seek to bring Coraza to Nginx and, eventually, Apache. In parallel to this expansion, Coraza will be developed further with its own feature set.

To learn more about CRS and Coraza, read [this CRS blog post](https://coreruleset.org/20211222/talking-about-modsecurity-and-the-new-coraza-waf/) which introduces Coraza.

## Commercial WAF Appliances

Dozens of commercial WAFs, both virtual and hardware-based, offer CRS as part of their service. Many of them use ModSecurity underneath, or some alternative implementation (although this is rare on the WAF appliance approach). Most of these commercial WAFs either don't offer the full feature set of CRS or they don't make it easily accessible. With some of these companies, there is often also a lack of CRS experience and knowledge.

The CRS project recommends evaluating these commercial appliance-based offerings in a holistic way before buying a license.

In light of the many, many appliance offerings on the market and the CRS project's relatively limited exposure, only a few offerings are listed here.

### HAProxy Technologies

HAProxy Technologies embeds ModSecurity v3 in three of its products via the Libmodsecurity module. ModSecurity is included with: HAProxy Enterprise, HAProxy ALOHA, and HAProxy Enterprise Kubernetes Ingress Controller. 

To learn more, visit the [HAProxy WAF solution page on haproxy.com](https://www.haproxy.com/solutions/web-application-firewall).

There is also a [Coraza SPOA](https://github.com/corazawaf/coraza-spoa) solution that works with HAProxy.

### Kemp/Progressive LoadMaster

The Kemp LoadMaster is a popular load balancer that integrates ModSecurity v2 and CRS in a typical way. It goes further than the competition with the support of most CRS features.

To learn more, read [this blog post about CRS on LoadMaster](https://kemptechnologies.com/blog/how-to-run-owasp-open-web-application-security-project-i-kemp-load-master/).

Kemp/Progressive is a sponsor of CRS.

### Loadbalancer.org

The load balancer appliance from Loadbalancer.org features WAF functionality based on Apache + ModSecurity v2 + CRS, sandwiched by HAProxy for load balancing. It's available as a hardware, virtual, and cloud appliance.

To learn more, read [this blog post about CRS at Loadbalancer.org](https://www.loadbalancer.org/blog/simplifying-web-application-security-with-the-core-rule-set-v3/).

### VMware® Avi Load Balancer

VMware® Avi Load Balancer is a modern virtual load balancer and proxy with strong WAF capabilities.

To learn more, read [VMware Avi Load Balancer WAF documentation](https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/avi-load-balancer/avi-load-balancer/30-2/vmware-avi-load-balancer-waf-guide/architecture/configuration.html)

## Existing CRS Integrations: Cloud and CDN Offerings

Most big cloud providers and CDNs provide a CRS offering. While originally these were mostly based on ModSecurity, over time they have all moved to alternative (usually proprietary) implementations of ModSecurity's SecLang configuration language, or they transpose the CRS rules written in SecLang into their own domain specific language (DSL).

The CRS project has some insight into some of these platforms and is in touch with most of these providers. The *exact specifics* are not really known, however, but what *is* known is that almost all of these integrators compromised and provide a *subset* of CRS rules and a *subset* of features, in the interests of ease of integration and operation.

{{% notice info %}}
The [CRS Status page project](https://github.com/coreruleset/coreruleset/wiki/DevRetreat21StatusPage) will be testing cloud and CDN offerings. As part of this effort, the CRS project will be documenting the results and even publishing code on how to quickly get started using CRS in CDN/cloud providers. This status page project is in development as of spring 2022.
{{% /notice %}}

A selection of these platforms are listed below, along with links to get more info.

### AWS WAF

{{% notice note %}}
AWS provides a rule set called the ["Core rule set (CRS) managed rule group"](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html) which "…provides protection against… commonly occurring vulnerabilities described in OWASP publications such as OWASP Top 10."

The CRS project does **not** believe that the AWS WAF "core rule set" is based on or related to OWASP CRS.
{{% /notice %}}

### Cloudflare WAF

Cloudflare WAF supports CRS as one of its WAF rule sets. Documentation on how to use it can be found in [Cloudflare's documentation](https://developers.cloudflare.com/waf/managed-rulesets/owasp-core-ruleset/).

### Fastly

Fastly has offered CRS as part of their Fastly WAF for several years, but they have started to migrate their existing customers to the recently acquired Signal Sciences WAF. Interestingly, Fastly is transposing CRS rules into their own Varnish-based WAF engine. Unfortunately, documentation on their legacy WAF offering has been removed.

### Google Cloud Armor

Google integrates CRS into its Cloud Armor WAF offering. Google runs the CRS rules on their own WAF engine. As of fall 2022, Google offers version 3.3.2 of CRS.

To learn more about CRS on Google's Cloud Armor, read [this document from Google](https://cloud.google.com/armor/docs/rule-tuning).

Google Cloud Armor is a sponsor of CRS.

### Microsoft Azure WAF

Azure Application Gateways can be configured to use the WAFv2 and [managed rules with different versions of CRS](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules). Azure provides the 3.2, 3.1, 3.0, and 2.2.9 CRS versions. **We recommend using version 3.2** (see our [security policy](https://github.com/coreruleset/coreruleset/blob/{{< param crs_dev_branch >}}/SECURITY.md) for details on supported CRS versions).

### Oracle WAF

The Oracle WAF is a cloud-based offering that includes CRS. To learn more, read [Oracle's WAF documentation](https://docs.oracle.com/en-us/iaas/Content/WAF/Concepts/waftuning.htm).

## Alternative Use Cases

Outside of the narrower implementation of a WAF, CRS can also be found in different security-related setups.

### Sqreen/Datadog

Sqreen uses a subset of CRS as an innovative part of their RASP offering. A few pieces of information about this offering can be found in [this Sqreen blog post](https://blog.sqreen.com/sqreen-october-release/).
