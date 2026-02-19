---
author: fzipi
date: '2026-02-18T22:11:21+02:00'
title: CRS Sandbox Security Policy
url: /crs-sandbox-policy
noindex: true
---

**Document Version:** 1.0
**Last Updated:** 2026-02-19
**Maintained by:** OWASP CRS Team

---

## 1. Overview

The OWASP CRS Sandbox (`https://sandbox.coreruleset.org/`) is a public, shared testing environment that allows users to evaluate CRS detection capabilities against real payloads — without requiring a local WAF installation. Because it is publicly accessible and shared across all users, responsible usage is essential to ensure availability, integrity, and fair access for everyone.

This policy applies to **all users** of the CRS Sandbox, including security researchers, integrators, administrators, exploit developers, and CRS rule writers.

For usage instructions, available options, and examples, see [Using the CRS Sandbox]({{% ref "6-4-using-the-crs-sandbox.md" %}}).

---

## 2. Intended Use

The sandbox is provided for the following **legitimate purposes**:

- Testing whether a known payload or CVE is detected by a specific CRS version or WAF engine.
- Evaluating CRS detection behavior during urgent security events (e.g., Log4Shell, Spring4Shell).
- Validating new or modified CRS rules during development and review.
- Research and publishing: generating detection evidence for vulnerability disclosures or security publications.
- Integration testing: verifying CRS behavior across different backends and CRS versions.

---

## 3. Acceptable Use

Users **may**:

- Send HTTP requests containing attack payloads representative of real-world exploits.
- Use any HTTP method, header manipulation, or request body encoding to test detection.
- Automate testing workflows within the rate limit specified in Section 5.
- Use the `X-Unique-Id` response header to reference a specific request when reporting issues.
- Select any available backend engine and CRS version for comparative testing.
- Adjust paranoia level and anomaly score thresholds for evaluation purposes.

---

## 4. Prohibited Use

Users **must not**:

- Use the sandbox as a **proxy or relay** to attack third-party systems.
- Attempt to **compromise the sandbox infrastructure** itself (e.g., exploiting the OpenResty frontend, backend containers, or supporting services).
- Deliberately trigger **ReDoS (Regular Expression Denial of Service)** conditions to degrade performance for other users. If a payload causes a timeout (HTTP 502), discontinue testing with that payload and report it as a potential ReDoS via a GitHub issue.
- Send **malformed HTTP requests** that are designed to exploit the frontend server rather than the WAF/CRS layer. Requests rejected by the frontend with HTTP 400 are not processed by CRS and provide no valid test results.
- Use the sandbox for **sustained load testing or stress testing** beyond the rate limits defined in Section 5.
- Attempt to **exfiltrate logs, audit data, or internal metadata** from the sandbox infrastructure.
- Use the sandbox for any activity that violates applicable **local, national, or international laws**.

---

## 5. Rate Limiting

To ensure fair access and availability for all users:

- **Do not send more than 10 requests per second.**
- Automated scripts and pipelines must implement appropriate throttling.
- Excessive usage may result in temporary blocking of the originating IP address without prior notice.

The OWASP CRS Team will attempt to scale capacity in response to increased demand, but cannot guarantee availability under excessive load.

---

## 6. Data and Privacy

- All requests sent to the sandbox are **logged and processed** by the sandbox infrastructure.
- Logs are written to an S3 bucket and an Elasticsearch cluster, and reviewed via Kibana by the OWASP CRS Team.
- **Do not send real personal data, credentials, API keys, or any sensitive information** in your requests.
- User-Agent strings and geolocation data are extracted from logs for operational analytics.
- By using the sandbox, you acknowledge that submitted request content may be retained and analyzed by the OWASP CRS Team for the purpose of improving CRS rules and sandbox infrastructure.

---

## 7. Responsible Disclosure

If you discover a **vulnerability in the sandbox infrastructure itself**, please do **not** attempt to exploit it and do **not** disclose it publicly. Instead, send a private email to `security@coreruleset.org` with:

1. A clear description of the vulnerability and its potential impact.
2. Steps to reproduce, including any relevant request details.
3. The `X-Unique-Id` response header value from your request, if available.

Please allow reasonable time for the team to assess and remediate before any public disclosure.

The OWASP CRS Team will respond as quickly as possible.

---

## 8. Known Limitations

Users should be aware of the following sandbox behaviors to avoid misinterpreting results:

| Issue | Cause | Symptom |
|---|---|---|
| Malformed HTTP requests not scanned by CRS | OpenResty or backend server rejects the request before CRS processes it | HTTP 400 response |
| ReDoS causing request failure | A payload triggers catastrophic backtracking in a regex | HTTP 502 after long delay |
| Default backend/version | Requests without `X-` headers use Apache 2 + ModSecurity 2.9 and the latest CRS release | Unexpected detection results when comparing engines |
| Detection-only mode | When `x-crs-mode: detection` is set, the WAF does not block; this affects score threshold behavior | No blocking even above threshold |

---

## 9. Sandbox Detection Output Is Not a Vulnerability Report

The CRS Sandbox is **intentionally designed to detect attacks and report matched rules**. Its output — including rule IDs, anomaly scores, and matched patterns — is publicly documented and expected behavior, not evidence of a vulnerability.

We periodically receive reports claiming a vulnerability was found in the sandbox, accompanied by `txt-matched-rules` output showing that a payload was detected. To be unambiguous: **a payload being detected by the sandbox is the sandbox working correctly**. This is not a security finding.

A valid security report for the CRS Sandbox would involve one of the following:

- A payload that **bypasses** CRS detection when it should be caught (a false negative in a specific CRS version or engine).
- A vulnerability in the **sandbox infrastructure itself** (e.g., a flaw in the OpenResty frontend, backend containers, or supporting services).
- A **ReDoS condition** triggered by a specific payload that causes backend instability.

Reports that consist solely of sandbox detection output, WAF audit logs, or anomaly scores generated through normal sandbox usage will be closed without further response.

---

## 10. No Bug Bounty Program

The OWASP CRS project is a volunteer-driven, open-source initiative. **We do not operate a bug bounty program and we do not offer monetary rewards** of any kind for vulnerability reports, security research, or any other contributions.

If you submit a report and receive a thank-you from the team, please understand that this is an acknowledgment of your effort and nothing more — it does not imply eligibility for compensation.

We are grateful for genuine contributions to CRS security, and we recognize meaningful work through community credit, changelog attribution, and public acknowledgment where appropriate.

---

## 11. Questions, Feedback, and Support

For questions, bugs, or feature suggestions related to the CRS Sandbox:

- Open a GitHub issue: `https://github.com/coreruleset/coreruleset/issues`
- Tag the issue appropriately (e.g., `sandbox`, `bug`, `enhancement`).

The OWASP CRS Team reviews issues regularly and will respond as resources allow.

---

## 12. Policy Updates

This policy may be updated at any time. Significant changes will be announced via the OWASP CRS GitHub repository. Continued use of the sandbox constitutes acceptance of the current policy.

---

*This policy is maintained by the OWASP CRS Team. The CRS Sandbox is a community resource — please use it responsibly.*
