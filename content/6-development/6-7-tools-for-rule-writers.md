---
title: Tools for Rule Writers
weight: 67
disableToc: false
chapter: false
aliases: ["../development/tools-for-rule-writers"]
---

> This page brings together essential tools that help rule writers create better, more effective CRS rules. From testing regular expressions to understanding database behavior, these resources will help you write rules using modern techniques and best practices.

Writing effective WAF rules requires understanding how attacks work, how payloads behave in different contexts, and how to create patterns that detect malicious behavior without causing false positives. The tools listed here will help you throughout the entire rule development process.

## Regular Expression Testing and Development

Regular expressions are the foundation of many CRS rules. These tools help you write, test, and optimize regex patterns.

### regex101

[https://regex101.com](https://regex101.com)

**Essential for rule development.** Provides real-time testing, detailed explanations of regex patterns, and performance analysis. Supports multiple regex flavors including PCRE (used by ModSecurity), Python, JavaScript, and Go. Features include:

- Real-time pattern matching with highlighting
- Detailed breakdown of regex components
- Quick reference and cheat sheet
- Community-shared patterns
- Regex debugging and step-through

### RegExr

[https://regexr.com](https://regexr.com)

A user-friendly regex testing tool with syntax highlighting and contextual help. Includes a searchable library of community patterns and supports PHP/PCRE and JavaScript regex flavors.

### Debuggex

[https://www.debuggex.com](https://www.debuggex.com)

Provides visual regex debugging with railroad diagrams that show how patterns match. Particularly useful for understanding complex regex structures. Supports JavaScript, Python, and PCRE.

### ExtendsClass Regex Tester

[https://extendsclass.com/regex-tester.html](https://extendsclass.com/regex-tester.html)

Online regex debugger supporting multiple languages including PHP (PCRE), Python, Ruby, JavaScript, Java, and MySQL. Features visualization of matches and helpful for testing regex across different platforms.

## Database and Query Testing Playgrounds

Understanding how databases handle SQL queries, comments, spacing, and special characters is crucial for writing effective SQLi detection rules. These online playgrounds let you test query variations without local database setup.

### SQLite Online

[https://sqliteonline.com](https://sqliteonline.com)

Fast and easy-to-use online SQL playground supporting SQLite, MySQL, PostgreSQL, MS SQL Server, and more. Ideal for quickly testing how different databases handle query variations.

### OneCompiler

Online compilers and playgrounds for multiple database systems:

- **MySQL**: [https://onecompiler.com/mysql](https://onecompiler.com/mysql)
- **MongoDB**: [https://onecompiler.com/mongodb](https://onecompiler.com/mongodb)
- **Redis**: [https://onecompiler.com/redis](https://onecompiler.com/redis)
- **PostgreSQL**: [https://onecompiler.com/postgresql](https://onecompiler.com/postgresql)

Excellent for testing how different database systems interpret commands, handle spacing, process comments, and respond to various payload variations.

### DB Fiddle

[https://www.db-fiddle.com](https://www.db-fiddle.com)

Simple interface for running SQL queries against SQLite, MySQL, and PostgreSQL. Includes sample queries and makes it easy to share test cases with others.

### PostgreSQL Playground (Aiven)

[https://aiven.io/tools/pg-playground](https://aiven.io/tools/pg-playground)

Free PostgreSQL-specific playground environment. Ideal for testing PostgreSQL-specific attack vectors and command syntax.

### RunSQL

[https://runsql.com](https://runsql.com)

Supports MySQL, PostgreSQL, and SQL Server with a clean interface for testing and learning SQL.

## Encoding and Decoding Tools

Attack payloads often use various encoding schemes to evade detection. These tools help you understand how payloads can be transformed and ensure your rules handle encoded variants.

### URL Encode/Decode

[https://www.urlencoder.org](https://www.urlencoder.org)

Quick URL encoding and decoding. Supports recursive decoding (up to 16 rounds) for payloads that are encoded multiple times. Essential for understanding URL-encoded attack payloads.

### Base64 Encoder/Decoder

[https://aqua-cloud.io/base64-encode-decoder](https://aqua-cloud.io/base64-encode-decoder)

Real-time Base64 encoding/decoding with URL-safe encoding support. Useful for exploring how API credentials, JWT tokens, and other Base64-encoded payloads are structured. For security, use only anonymized or dummy data and never paste real secrets, such as live API keys or JWTs, into external online tools.

### FusionAuth URL Encoder/Decoder

[https://fusionauth.io/dev-tools/url-encoder-decoder](https://fusionauth.io/dev-tools/url-encoder-decoder)

Encode and decode URL parameters with instant conversion. Helps understand safe transmission of special characters in URLs.

### Toolquix Encode/Decode

[https://toolquix.com/encode-decode](https://toolquix.com/encode-decode)

Multi-format encoding tool supporting ASCII to hex, Base32, ROT13, and more. Useful for testing various encoding transformations that attackers might use.

## XSS and Security Payload Testing

Cross-site scripting (XSS) attacks use various techniques to bypass filters. These resources help you understand XSS vectors and test payload variations.

### PortSwigger XSS Cheat Sheet

[https://portswigger.net/web-security/cross-site-scripting/cheat-sheet](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet)

Comprehensive and regularly updated XSS payload reference. Contains vectors designed to bypass WAFs and filters. Essential resource for understanding current XSS techniques and testing rule effectiveness.

### LRQA XSS Payload Generator

[https://www.lrqa.com/en/cyber-labs/cross-site-scripting-xss-payload-generator](https://www.lrqa.com/en/cyber-labs/cross-site-scripting-xss-payload-generator)

Interactive tool for generating XSS payloads with various encoding and obfuscation techniques. Helps test how rules handle different XSS variations.

## HTTP Request Testing Tools

Testing how your rules respond to actual HTTP requests is crucial. These tools help simulate requests and analyze responses.

### HTTPie

[https://httpie.io](https://httpie.io)

Modern, user-friendly command-line HTTP client. More intuitive than curl with JSON support, syntax highlighting, and better output formatting. Great for testing rule behavior with various HTTP requests.

### Hurl

[https://hurl.dev](https://hurl.dev)

Lightweight HTTP testing tool built on libcurl. Allows you to run and test HTTP requests with a simple plain-text format. Excellent for creating repeatable test scenarios.

## CRS-Specific Development Tools

These tools are specifically designed for CRS development and are documented elsewhere in this guide.

### crs-toolchain

The CRS developer's toolbelt including the regexp assembler for building optimized regular expressions from data files. See [crs-toolchain documentation]({{% ref "6-2-crs-toolchain.md" %}}).

### go-ftw

Framework for Testing WAFs in Go. Essential for writing and running tests for your rules. See [testing documentation]({{% ref "6-5-testing-the-rule-set.md" %}}).

### Regexp Assembly Syntax Highlighter

Visual Studio Code extension for syntax highlighting of regexp assembly files. Makes it easier to write and maintain regexp data files. Available at [github.com/coreruleset/regexp-assemble-syntax](https://github.com/coreruleset/regexp-assemble-syntax).

For a complete list of CRS development tools including testing frameworks, parsers, and Docker containers, see [Useful Tools]({{% ref "6-6-useful_tools.md" %}}).

## Rule Writing Workflow

Here's a recommended workflow for developing new rules, incorporating many of the tools listed above:

### 1. Understand the Attack

- Research the attack technique you want to detect
- Collect real-world payload examples
- Understand how the payload works in its target context

### 2. Test Payload Behavior

- Use database playgrounds (SQLite Online, OneCompiler, etc.) to understand how databases process the payload
- Test variations: spacing, comments, case sensitivity, encoding
- Note which variations are functionally equivalent and must be detected

### 3. Develop Detection Pattern

- Draft a regular expression to match the attack pattern
- Use regex101.com to test and refine your pattern
- Test against both malicious payloads and legitimate traffic
- Optimize for performance (avoid catastrophic backtracking)

### 4. Consider Evasion Techniques

- Test encoded versions using encoding/decoding tools
- Consider how attackers might obfuscate the payload
- Ensure your pattern handles common bypass techniques

### 5. Decide on Rule Placement

- Determine if this is a new attack requiring a new rule
- Or if it's a variant that should be added to an existing rule
- **Preference**: Extend existing rules when possible rather than creating new ones

### 6. Create or Update Rule

- If extending an existing rule, update the regexp-assemble data file
- Use crs-toolchain to generate the optimized rule
- Follow [contribution guidelines]({{% ref "6-1-contribution-guidelines.md" %}})

### 7. Test Thoroughly

- Write go-ftw tests for your rule
- Test against known attack payloads
- Test against legitimate traffic to minimize false positives
- Test with different payload encodings
- Run the full test suite to ensure no regressions

### 8. Document and Submit

- Document the attack technique your rule detects
- Explain any non-obvious pattern choices
- Submit a pull request following CRS contribution guidelines

## Tips for Effective Rule Writing

- **Start simple**: Begin with basic patterns and add complexity only when needed
- **Test extensively**: Use multiple tools to verify your understanding of attack behavior
- **Consider performance**: Use regex101's performance features to identify slow patterns
- **Think like an attacker**: Use encoding and obfuscation tools to find bypass techniques
- **Minimize false positives**: Test against legitimate traffic patterns
- **Collaborate**: Share your work with the community for feedback

## Additional Resources

- **CRS Contribution Guidelines**: [Section 6.1]({{% ref "6-1-contribution-guidelines.md" %}})
- **Assembling Regular Expressions**: [Section 6.3]({{% ref "6-3-assembling-regular-expressions.md" %}})
- **Testing the Rule Set**: [Section 6.5]({{% ref "6-5-testing-the-rule-set.md" %}})
- **OWASP Testing Guide**: [owasp.org/www-project-web-security-testing-guide](https://owasp.org/www-project-web-security-testing-guide)

## Contributing to This Page

If you know of other useful tools for rule writers, please open an issue or submit a pull request at [github.com/coreruleset/documentation](https://github.com/coreruleset/documentation).

---

**Sources:**
- [regex101](https://regex101.com/)
- [RegExr](https://regexr.com/)
- [Debuggex](https://www.debuggex.com/)
- [ExtendsClass Regex Tester](https://extendsclass.com/regex-tester.html)
- [SQLite Online](https://sqliteonline.com/)
- [OneCompiler](https://onecompiler.com/)
- [DB Fiddle](https://www.db-fiddle.com/)
- [PostgreSQL Playground](https://aiven.io/tools/pg-playground)
- [RunSQL](https://runsql.com/)
- [URL Encoder](https://www.urlencoder.org/)
- [Aqua Cloud Base64 Encoder](https://aqua-cloud.io/base64-encode-decoder/)
- [FusionAuth URL Encoder](https://fusionauth.io/dev-tools/url-encoder-decoder)
- [Toolquix Encode/Decode](https://toolquix.com/encode-decode)
- [PortSwigger XSS Cheat Sheet](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet)
- [LRQA XSS Payload Generator](https://www.lrqa.com/en/cyber-labs/cross-site-scripting-xss-payload-generator/)
- [HTTPie](https://httpie.io/)
- [Hurl](https://hurl.dev/)
