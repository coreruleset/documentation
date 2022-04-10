---
title: "Engine and Integration Options"
menuTitle: "Engine and Integration Options"
chapter: false
weight: 5
---

The Core Rule Set can be run using a compatible WAF engine. The CRS can also be used via a number of services which feature CRS integration, such as cloud and CDN-based WAF offerings.

## Compatible WAF Engines

### ModSecurity

ModSecurity comes in two distinct flavors: ModSecurity v2 and ModSecurity v3 (aka libmodsecurity). Originally, ModSecurity v2 was designed to work as an Apache module. This is the more stable engine around, and the CRS base target. Then evolution (or reimplementation) is v3 where so the core engine is moved to a library, libmodsecurity, and detached from Apache. Then connectors were implemented to bridge between Web Servers and libmodsecurity. Now for v3, the most stable connector around is the one for Nginx.

{{% notice tip %}}
Not all features from ModSecurity v2 were implemented in v3. But all the features implemented by the CRS should be compatible with both engines
{{% /notice %}}

Usage depends a bit on your expertise and the software you use normally. Recommended setups are:
- Apache with ModSecurity v2
- Nginx with ModSecurity v3

Both "flavors" can be deployed quickly using our [provided containers](https://github.com/coreruleset/modsecurity-crs-docker).
 
### Coraza WAF Engine

The OWASP Coraza WAF engine is 100% compatible with CRS v4 major release. See [their website](https://coraza.io/) on their deployment options. 

{{% notice warning %}}
Coraza WAF is not a replacement for ModSecurity. It is a **new engine** compatible enough to run CRS, but will be growing with its new set of features. 
{{% /notice %}}

## Existing CRS Integrations: Cloud and CDN Offerings

{{% notice info %}}
The [CRS Status page project](https://github.com/coreruleset/coreruleset/wiki/DevRetreat21StatusPage) will be testing Cloud and CDN offerings. As part of this effort we will be documenting results and even publishing code to quickly get started using CRS in CDN/cloud providers.
{{% /notice %}}

### AWS WAF

AWS provides an [abridged version of the Core Rule set](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html). It is confusing initially because as a managed rule set it is called `AWSManagedRulesCommonRuleSet`, but technically is their partial implementation of that resembles the CRS. 

### Microsoft Azure WAF

Azure Application Gateways can be configured to use the WAFv2 and [managed rules with different versions of the CRS](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules). Azure provides the 3.2, 3.1, 3.0, or 2.2.9 versions, and we recommend using 3.2 (see our [security policy](https://github.com/coreruleset/coreruleset/blob/v3.4/dev/SECURITY.md)).

### CloudFlare WAF

Cloudflare WAF supports using CRS. [Here](https://developers.cloudflare.com/waf/managed-rulesets/owasp-core-ruleset/) you can find the documentation on how to use it.