+++
title = "Rules"
chapter = false
weight = 3
pre = "<b>3. </b>"
+++

# What's In The Rules

| File                                                    | Description |
| --------------------------------------------------------| ------------|
| **REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example** | Configuration Path:   `rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example`.
| | This file is used to add LOCAL exceptions for your site. Often in this
  file we would see rules that short-circuit inspection and allow
  certain transactions to skip through inspection.
 `Example: SecRule REMOTE_ADDR "@ipMatch 192.168.1.100" "phase:1,id:'981033',t:none,nolog,pass,ctl:ruleEngine=Off"`|
| **REQUEST-901-INITIALIZATION.conf** | TODO |
| **REQUEST-903.9001-DRUPAL-EXCLUSION-RULES.conf
  REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf
  REQUEST-903.9003-NEXTCLOUD-EXCLUSION-RULES.conf
  REQUEST-903.9004-DOKUWIKI-EXCLUSION-RULES.conf
  REQUEST-903.9005-CPANEL-EXCLUSION-RULES.conf
  REQUEST-903.9006-XENFORO-EXCLUSION-RULES.conf** | TODO |


| **REQUEST-905-COMMON-EXCEPTIONS**
| Configuration Path:
  `rules/REQUEST-905-COMMON-EXCEPTIONS.conf`
|
| Some rules are quite prone to causing false positives in well
  established software, such as Apache callbacks or Google Analytics
  tracking cookie. This file offers rules that will allow the
  transactions to avoid triggering these false positives.

| **REQUEST-910-IP-REPUTATION**
| Configuration Path:
  `rules/REQUEST-910-IP-REPUTATION.conf`
|
| These rules deal with detecting traffic from IPs that have previously
  been involved with malicious activity, either on our local site or
  globally.


  **REQUEST-911-METHOD-ENFORCEMENT**
  TODO

| **REQUEST-912-DOS-PROTECTION**
| Configuration Path:
  `rules/REQUEST-912-DOS-PROTECTION.conf`
|
| The rules in this file will attempt to detect some level 7 DoS (Denial
  of Service) attacks against your server.

| **REQUEST-913-SCANNER-DETECTION**
| Configuration Path:
  `rules/REQUEST-913-SCANNER-DETECTION.conf`
|
| These rules are concentrated around detecting security tools and
  scanners.

| **REQUEST-920-PROTOCOL-ENFORCEMENT**
| Configuration Path:
  `rules/REQUEST-20-PROTOCOL-ENFORCEMENT.conf`
|
| The rules in this file center around detecting requests that either
  violate HTTP or represent a request that no modern browser would
  generate, for instance missing a user-agent.

| **REQUEST-921-PROTOCOL-ATTACK**
|
| Configuration Path: `rules/REQUEST-21-PROTOCOL-ATTACK.conf`
| The rules in this file focus on specific attacks against the HTTP
  protocol itself such as HTTP Request Smuggling and Response Splitting.

| **REQUEST-930-APPLICATION-ATTACK-LFI**
|
| Configuration Path: `rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf`

| These rules attempt to detect when a user is trying to include a file
  that would be local to the webserver that they should not have access
  to. Exploiting this type of attack can lead to the web application or
  server being compromised.

| **REQUEST-931-APPLICATION-ATTACK-RFI**
| Configuration Path: `rules/REQUEST-31-APPLICATION-ATTACK-RFI.conf`
|
| These rules attempt to detect when a user is trying to include a
  remote resource into the web application that will be executed.
  Exploiting this type of attack can lead to the web application or
  server being compromised.

  **REQUEST-932-APPLICATION-ATTACK-RCE.conf
  REQUEST-933-APPLICATION-ATTACK-PHP.conf
  REQUEST-934-APPLICATION-ATTACK-NODEJS.conf**

  TODO

  **REQUEST-941-APPLICATION-ATTACK-XSS.conf**
  TODO


| **REQUEST-942-APPLICATION-ATTACK-SQLI**
| Configuration Path: `rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf`
|
| Within this configuration file we provide rules that protect against
  SQL injection attacks. SQLi attackers occur when an attacker passes
  crafted control characters to parameters to an area of the application
  that is expecting only data. The application will then pass the
  control characters to the database. This will end up changing the
  meaning of the expected SQL query.

| **REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION**
| Configuration Path: `rules/REQUEST-43-APPLICATION-ATTACK-SESSION-FIXATION.conf`
|
| These rules focus around providing protection against Session Fixation
  attacks.

  **REQUEST-944-APPLICATION-ATTACK-JAVA**
  TODO

| **REQUEST-949-BLOCKING-EVALUATION**
| Configuration Path: `rules/REQUEST-49-BLOCKING-EVALUATION.conf`
|
| These rules provide the anomaly based blocking for a given request. If
  you are in anomaly detection mode this file must not be deleted.

| **RESPONSE-954-DATA-LEAKAGES-IIS**
| Configuration Path:
  `rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf`
|
| These rules provide protection against data leakages that may occur
  because of Microsoft IIS

| **RESPONSE-952-DATA-LEAKAGES-JAVA**
| Configuration Path: `rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf`
|
| These rules provide protection against data leakages that may occur
  because of Java

| **RESPONSE-953-DATA-LEAKAGES-PHP**
| Configuration Path:
  `rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf`
|
| These rules provide protection against data leakages that may occur
  because of PHP

| **RESPONSE-950-DATA-LEAKAGES**
| Configuration Path:
  `rules/RESPONSE-950-DATA-LEAKAGES.conf`
|
| These rules provide protection against data leakages that may occur
  genericly

| **RESPONSE-951-DATA-LEAKAGES-SQL**
| Configuration Path:
  `rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf`
|
| These rules provide protection against data leakages that may occur
  from backend SQL servers. Often these are indicative of SQL injection
  issues being present.

| **RESPONSE-959-BLOCKING-EVALUATION**
| Configuration Path: `rules/RESPONSE-959-BLOCKING-EVALUATION.conf`
|
| These rules provide the anomaly based blocking for a given response.
  If you are in anomaly detection mode this file must not be deleted.

| **RESPONSE-980-CORRELATION**
| Configuration Path: `rules/RESPONSE-980-CORRELATION.conf`
|
| The rules in this configuration file facilitate the gathering of data
  about successful and unsuccessful attacks on the server.

  **REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example**
  Configuration Path: `rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example`

  This file is used to add LOCAL exceptions for your site. Often in this
  file we would see rules that short-circuit inspection and allow
  certain transactions to skip through inspection.
