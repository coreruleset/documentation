---
title: "Engine and Integration Options"
menuTitle: "Engine and Integration Options"
chapter: false
weight: 5
---

> The Core Rule Set can be run using a compatible WAF engine. CRS can also be used via a number of services which feature CRS integration, such as cloud and CDN-based WAF offerings.

## Compatible WAF Engines

### ModSecurity

ModSecurity comes in two distinct flavors:

- ModSecurity v2
- ModSecurity v3 (aka _libmodsecurity_)

Originally, ModSecurity v2 was designed to work as an Apache module. This is the more stable engine of those available, and it's also the CRS base target.

The evolution (or reimplementation) of v2 was v3, where the core engine was moved to a library, _libmodsecurity_, and detached from Apache. Connectors were then implemented to bridge between web servers and libmodsecurity. For v3, the most stable connector available is the [Nginx connector](https://github.com/SpiderLabs/ModSecurity-nginx).

{{% notice note %}}
Not all features from ModSecurity v2 were implemented in v3, but **all features implemented by CRS should be compatible with both ModSecurity engines**.

For full details on implemented features, refer to the ModSecurity [v2](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)) and [v3](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-%28v3.x%29) reference manuals on GitHub.
{{% /notice %}}

Which engine to choose depends on the available expertise and the software used normally (i.e., Apache or Nginx). Recommended setups are:

- Apache with ModSecurity v2
- Nginx with ModSecurity v3

Both of these combinations can be quickly deployed using our [provided Docker containers](https://github.com/coreruleset/modsecurity-crs-docker).
 
### Coraza WAF Engine

The OWASP Coraza WAF engine is 100% compatible with the CRS v4 major release. See the [Coraza website](https://coraza.io/) for information on deployment options. 

{{% notice info %}}
Coraza WAF is not a replacement for ModSecurity. It is a **new engine** which is compatible enough to run CRS, but will be growing with its own new set of features. 
{{% /notice %}}

## Existing CRS Integrations: Cloud and CDN Offerings

{{% notice info %}}
The [CRS Status page project](https://github.com/coreruleset/coreruleset/wiki/DevRetreat21StatusPage) will be testing cloud and CDN offerings. As part of this effort, we will be documenting results and even publishing code on how to quickly get started using CRS in CDN/cloud providers.
{{% /notice %}}

### AWS WAF

AWS provides an [abridged version of the Core Rule set](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html). It's confusing initially because, as a managed rule set, it's called `AWSManagedRulesCommonRuleSet`, but technically it's their partial implementation of / resembles the CRS. 

### Microsoft Azure WAF

Azure Application Gateways can be configured to use the WAFv2 and [managed rules with different versions of CRS](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules). Azure provides the 3.2, 3.1, 3.0, and 2.2.9 CRS versions. **We recommend using version 3.2** (see our [security policy](https://github.com/coreruleset/coreruleset/blob/v3.4/dev/SECURITY.md) for details on supported CRS versions).

### Cloudflare WAF

Cloudflare WAF supports using CRS. Documentation on how to use it can be found [here](https://developers.cloudflare.com/waf/managed-rulesets/owasp-core-ruleset/).
