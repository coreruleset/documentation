---
title: Paranoia Levels
weight: 20
disableToc: false
chapter: false
---

> Paranoia levels are an essential concept when working with CRS. This page explains the concept behind paranoia levels and how to work with them on a practical level.

## Introduction to Paranoia Levels

**The paranoia level (PL) makes it possible to define how aggressive CRS is.** Paranoia level 1 (PL 1) provides a set of rules that hardly ever trigger a false alarm (ideally never, but it can happen, depending on the local setup). PL 2 provides additional rules that detect more attacks (these rules operate *in addition* to the PL 1 rules), but there's a chance that the additional rules will also trigger new false alarms over perfectly legitimate HTTP requests.

This continues at PL 3, where more rules are added, namely for certain specialized attacks. This leads to even more false alarms. Then at PL 4, the rules are so aggressive that they detect almost every possible attack, yet they also flag a lot of legitimate traffic as malicious.

![Onion model diagram showing the four paranoia levels as ellipses. Each successive paranoia level is a superset of the previous one.](https://coreruleset.org/docs/images/pl_onion_no_fonts.svg?width=25em)

A higher paranoia level makes it harder for an attacker to go undetected. Yet this comes at the cost of more false positives: more false alarms. That's the downside to running a rule set that detects almost everything: your business / service / web application is also disrupted.

When false positives occur they need to be tuned away. In ModSecurity parlance: rule exclusions need to be written. A rule exclusion is a rule that disables another rule, either disabled completely or disabled partially only for certain parameters or for certain URIs. This means **the rule set remains intact** yet the CRS installation is no longer affected by the false positives.

{{% notice note %}}
Depending on the complexity of the service (web application) in question and on the paranoia level, the process of writing rule exclusions can be a *substantial* amount of work.

This page won't explore the problem of handling false positives further: for more information on this topic, see the appropriate chapter or refer to the [tutorials at netnea.com](https://www.netnea.com/cms/apache-tutorials/).
{{% /notice %}}

## Description of the Four Paranoia Levels

The CRS project views the four paranoia levels as follows:

| Paranoia Level | Description |
| -------------- | ----------- |
| **1** | Baseline security with a minimal need to tune away false positives. This is CRS for everybody running an HTTP server on the internet. Please report any false positives encountered with a PL 1 system [via GitHub](https://github.com/coreruleset/coreruleset/issues/new/choose). |
| **2** | Rules that are adequate when real user data is involved. Perhaps an off-the-shelf online shop. Expect to encounter false positives and learn how to tune them away. |
| **3** | Online banking level security with lots of false positives. From a project perspective, false positives are accepted and expected here, so it's important to learn how to write rule exclusions. |
| **4** | Rules that are so strong (or paranoid) they're adequate to protect the "crown jewels". To be used at one's own risk: be prepared to face a large number of false positives. |

## Choosing an Appropriate Paranoia Level

It's important to think about a service's security requirements. The difference between protecting a personal website and the admin gateway controlling access to an enterprise’s Active Directory are very different. The paranoia level needs to be chosen accordingly, while also considering the resources (time) required to tune away false positives at higher paranoia levels.

Running at  the highest paranoia level, PL 4, may seem appealing from a security standpoint, but *it could take many weeks to tune away the false positives encountered*. It is crucial to have enough time to fully deal with all false positives.

{{% notice warning %}}
Failure to properly tune an installation runs the risk of exposing users to a vast number of false positives. This can lead to a poor user experience, and might ultimately lead to a decision to completely disable CRS. As such, **setting a high PL in blocking mode *without* adequate tuning to deal with false positives is very risky**.
{{% /notice %}}

If working in an enterprise environment, consider developing an internal policy to map the risk levels and security needs of different assets to the minimum acceptable paranoia level to be used for them, for example:

* **Risk Class 0**: No personal data involved → PL 1
* **Risk Class 1**: Personal data involved, e.g. names and addresses → PL 2
* **Risk Class 2**: Sensitive data involved, e.g. financial/banking data; highest risk class → PL 3

## Setting the Paranoia Level

If using a native CRS installation on a web application firewall, the paranoia level is defined by setting the variable `tx.paranoia_level` in the file `crs-setup.conf`. This is done in rule 900000, but technically the variable can be set in the Apache or Nginx configuration instead.

If running CRS where it has been integrated into a commercial product or CDN then support varies. Some vendors expose the PL setting in the GUI while other vendors require a custom rule to be written that sets `tx.paranoia_level`. Unfortunately, there are also vendors that don't allow the PL to be set at all. (The CRS project considers this to be an incomplete CRS integration, since paranoia levels are a defining feature of CRS.)

## How Paranoia Levels Relate to Anomaly Scoring

It's important to understand that paranoia levels and CRS anomaly scoring (the CRS anomaly threshold/limit) are **two entirely different things with no direct connection**. The paranoia level controls the number of rules that are enabled while the anomaly threshold defines how many rules can be triggered before a request is blocked.

At the conceptual level, these two ideas *could* be mixed if the goal was to create a particularly granular security concept. For example, saying "we define the anomaly threshold to be 10, but we compensate for this by running at paranoia level 3, which we acknowledge brings more rule alerts and higher anomaly scores."

This is *technically* correct but it overlooks the fact that there are attack categories where CRS scores very low. For example, there is a plan to introduce a new rule to detect POP3 and IMAP injections: this will be a single rule, so, under normal circumstances, an IMAP injection would never score more than 5. Therefore, an installation running at an anomaly threshold of 10 could never block an IMAP injection, even if running at PL 3. In light of this, it's generally advised to **keep things simple and separate**: a CRS installation should aim for an anomaly threshold of 5 and a paranoia level as deemed appropriate.

## Moving to a Higher Paranoia Level

### Introducing the *Executing Paranoia Level*

Consider an example successful CRS installation: it operates at paranoia level 1, a handful of rule exclusions are in place to deal with false positives, and the inbound anomaly score threshold is set to 5 which blocks would-be attackers immediately. Things are running smoothly at paranoia level 1, but imagine that there's now a requirement to increase the level of security by raising the paranoia level to 2. Moving to PL 2 will *almost certainly* cause new false positives: given the strict anomaly score threshold of 5, these will likely cause legitimate users to be blocked.

There's a simple, but **risky**, way to raise the paranoia level of a working and tuned CRS installation: raise the anomaly score threshold for a period of time, in order to account for the additional false positives that are anticipated. Raising the anomaly score threshold will allow through attacks that would have been blocked previously. The idea of *decreasing* security in order to *improve* it is counter-intuitive, as well as being bad practice.

There is a better solution. First, think of the paranoia level as being the "blocking paranoia level". The rules enabled in the blocking paranoia level count towards the anomaly score threshold, which is used to determine whether or not to block a given request. Now introduce an *additional* paranoia level: the "executing paranoia level". By default, the executing paranoia level is automatically set to be equal to the blocking paranoia level. If, however, the executing paranoia level is set to be *higher* than the blocking paranoia level then the additional rules from the higher paranoia level are *executed* but will never count towards the anomaly score threshold used to make the blocking decision.

*Example: Blocking paranoia level of 1 and executing paranoia level of 2*

![Diagram showing a scenario where the blocking paranoia level and the executing paranoia level are different. The active and inactive paranoia levels are emphasized to explain the concept.](https://coreruleset.org/images/2021/10/executing-paranoia-level-1.png?width=25em)

**The executing paranoia level allows rules from a higher paranoia level to be run, and potentially to trigger false positives, without increasing the probability of blocking legitimate users.** Any new false positives can then be tuned away using rule exclusions. Once ready and with all the new rule exclusions in place, the blocking paranoia level can then be raised to match the executing paranoia level. This approach is a flexible and secure way to raise the paranoia level on a working production system *without* the risk of new false positives blocking users in error.

## Moving to a Lower Paranoia Level

It is always possible to lower the paranoia level in order to experience fewer false positives, or none at all. The way that the rule set is constructed, lowering the paranoia level *always* means fewer or no false positives; raising the paranoia level is *very likely* to introduce more false positives.

## Further Reading

For a slightly longer explanation of paranoia levels, please refer to [our blog post on the subject](https://coreruleset.org/20211028/working-with-paranoia-levels/). The blog post also discusses the pros and cons of dynamically setting the paranoia level on a per-request basis, firstly by geolocation (i.e. a lower PL for domestic traffic and a higher PL for non-domestic traffic) and secondly based on previous behavior (i.e. a user is dealt with at PL 1, but if they ever trigger a rule then they're handled at PL 2 for all future requests).
