---
title: Using the CRS Sandbox
weight: 64
disableToc: false
chapter: false
aliases: ["../development/sandbox"]
---

{{% notice style="info" icon="flask" %}}
The CRS Sandbox is a shared public resource. Please review the [CRS Sandbox Security Policy]({{% ref "6-7-crs-sandbox-security-policy.md" %}}) before use.
{{% /notice %}}

## Introducing the CRS Sandbox

We have set up a public **CRS Sandbox** which you can use to send attacks at the CRS. You can choose between various WAF engines and CRS versions. The sandbox parses audit logs and returns our detections in an easy and useful format.

The sandbox is useful for:

- integrators and administrators: you can test out our response in case of an urgent security event, such as the Log4j vulnerability;
- exploit developers/researchers: if you have devised a payload, you can test beforehand if it will be blocked by the CRS and by which versions;
- CRS developers/rule writers: you can quickly check if the CRS catches a (variant of an) exploit without the hassle of setting up your own CRS instance.

## Quick reference

{{< tabs title="Sandbox Headers" >}}
{{% tab title="Backend" %}}
**Header:** `x-backend`

| Value | Engine |
|-------|--------|
| `apache` (default) | Apache 2 + ModSecurity 2.9 |
| `nginx` | Nginx + ModSecurity 3 |
| `coraza` | Coraza WAF on Caddy |

```bash
curl -H "x-backend: coraza" \
  -H "x-format-output: txt-matched-rules" \
  'https://sandbox.coreruleset.org/?file=/etc/passwd'
```
{{% /tab %}}
{{% tab title="CRS Version" %}}
**Header:** `x-crs-version`

| Value | Description |
|-------|-------------|
| `v4-lts` (default) | Newest release of the CRS 4 long-term support line (currently 4.25.x) |
| `v3-lts` | Newest release of the CRS 3.3 line (currently 3.3.x); `apache` and `nginx` only |
| `latest` | Newest CRS release (currently 4.30.x) |

The values are aliases, not version numbers. The `X-CRS-Version` response header tells you the exact tag that handled your request.

```bash
curl -H "x-crs-version: v3-lts" \
  -H "x-format-output: txt-matched-rules" \
  'https://sandbox.coreruleset.org/?file=/etc/passwd'
```
{{% /tab %}}
{{% tab title="Paranoia Level" %}}
**Header:** `x-crs-paranoia-level` (blocking and detection paranoia level)

| Value | Description |
|-------|-------------|
| `1` (default) | Least strict |
| `2` | Moderate |
| `3` | Strict |
| `4` | Most strict |

**Header:** `x-crs-detection-paranoia-level` (detection paranoia level only, `1` to `4`; must not be lower than the paranoia level)

```bash
curl -H "x-crs-paranoia-level: 3" \
  -H "x-format-output: txt-matched-rules" \
  'https://sandbox.coreruleset.org/?file=/etc/passwd'
```
{{% /tab %}}
{{% tab title="Mode & Thresholds" %}}
**Header:** `x-crs-mode`

| Value | Description |
|-------|-------------|
| _(omitted)_ | Blocking mode |
| `detection` | Detection only (`SecRuleEngine DetectionOnly`): rules match, nothing is blocked |

**Header:** `x-crs-inbound-anomaly-score-threshold` (default: `5`)

**Header:** `x-crs-outbound-anomaly-score-threshold` (default: `4`)

```bash
curl -H "x-crs-mode: detection" \
  -H "x-crs-inbound-anomaly-score-threshold: 10" \
  -H "x-format-output: txt-matched-rules" \
  'https://sandbox.coreruleset.org/?file=/etc/passwd'
```
{{% /tab %}}
{{% tab title="Output Format" %}}
**Header:** `x-format-output`

| Value | Description |
|-------|-------------|
| _(omitted)_ | Full audit log as JSON (browsers get an HTML report instead) |
| `txt-matched-rules` | Human-readable matched rules, one per line |
| `txt-matched-rules-extended` | Extended text with explanation |
| `json-matched-rules` | JSON list of `{id, message, paranoia_level}` |
| `json-report` | JSON report: engine, CRS tag, HTTP status, `blocked`, anomaly scores and the matched rules with their matched data |
| `csv-matched-rules` | CSV formatted |
| `html-matched-rules` | HTML table |

```bash
curl -H "x-format-output: json-report" \
  'https://sandbox.coreruleset.org/?file=/etc/passwd' | jq .
```
{{% /tab %}}
{{% tab title="Full Examples" %}}
**Apache** with text output and the CRS 4 LTS line:

```bash
curl -H "x-backend: apache" \
  -H "x-crs-version: v4-lts" \
  -H "x-format-output: txt-matched-rules" \
  'https://sandbox.coreruleset.org/?file=/etc/passwd'
```

**Nginx** with JSON output and CRS 3.3:

```bash
curl -H "x-backend: nginx" \
  -H "x-crs-version: v3-lts" \
  -H "x-format-output: json-matched-rules" \
  'https://sandbox.coreruleset.org/?q=<script>alert(1)</script>' | jq .
```

**Coraza** with extended text output and the newest CRS release:

```bash
curl -H "x-backend: coraza" \
  -H "x-crs-version: latest" \
  -H "x-format-output: txt-matched-rules-extended" \
  'https://sandbox.coreruleset.org/?cmd=cat+/etc/shadow'
```
{{% /tab %}}
{{< /tabs >}}

## Basic usage

The sandbox is located at https://sandbox.coreruleset.org/.

An easy way to use the sandbox is to send requests to it with `curl`, although you can use any HTTPS client. The sandbox answers CORS preflights, so a web page can call it from the browser as well.

The sandbox has many options, which you can change by adding HTTP headers to your request. One is very important so we will explain it first; this is the `X-Format-Output: txt-matched-rules` header. If you add this header to your request, the sandbox will parse the WAF's output, and return to you the matched CRS rule IDs with descriptions, and the score for your request.

### Example

```bash
curl -H "x-format-output: txt-matched-rules" https://sandbox.coreruleset.org/?file=/etc/passwd

930120 PL1 OS File Access Attempt
932160 PL1 Remote Command Execution: Unix Shell Code Found
949110 PL? Inbound Anomaly Score Exceeded (Total Score: 10)
980170 PL? Anomaly Scores: (Inbound Scores: blocking=10, detection=10, per_pl=10-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=5, RCE=5, PHPI=0, HTTP=0, SESS=0, COMBINED_SCORE=10)
```

In this example, we sent `?file=/etc/passwd` as a GET payload. The CRS should catch the string `/etc/passwd` which is on our blocklist. Try out the command in a terminal now if you like!

You can send anything you want at the sandbox, for instance, you can send HTTP headers, POST data, use various HTTP methods, et cetera. Behind every WAF sits a small HTTP mirror ([go-httpbin](https://github.com/mccutchen/go-httpbin)) that accepts any path and method, so `/get`, `/post?x=1` or `/anything/you/like` all work. The response body is always the WAF's verdict in the format you asked for, not the mirror's answer.

If no attack is detected, the sandbox returns an empty result in the requested format (e.g., an empty JSON array `[]` for `json-matched-rules`, or an empty response for `txt-matched-rules`).

The response status code is the one the WAF produced: a `403` means the request was blocked, a `200` means it went through. In blocking mode a blocked request always lists rule `949110` (inbound anomaly score exceeded).

The sandbox also adds a few headers to the response. `X-Unique-ID` contains a unique value that you can use to refer to your request when communicating with us. `x-backend` names the service that answered and `X-CRS-Version` the exact CRS tag it runs. With `curl -i` you can see the returned headers.

### Example showing the response headers

```bash
curl -i -H 'x-format-output: txt-matched-rules' \
  'https://sandbox.coreruleset.org/?test=system()'
HTTP/1.1 403 Forbidden
Date: Wed, 21 Oct 2026 12:30:15 GMT
Content-Type: text/plain; charset=iso-8859-1
Transfer-Encoding: chunked
Connection: keep-alive
X-Unique-ID: atiwV04_IxXbFP_EhPQqOgAAAME
X-CRS-Version: v4.25.2
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: x-backend, x-crs-version, x-unique-id
x-backend: apache-v4-lts

933160 PL1 PHP Injection Attack: High-Risk PHP Function Call Found
949110 PL? Inbound Anomaly Score Exceeded (Total Score: 5)
980170 PL? Anomaly Scores: (Inbound Scores: blocking=5, detection=5, per_pl=5-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=0, RCE=0, PHPI=5, HTTP=0, SESS=0, COMBINED_SCORE=5)
```

### Discovering what is available

`GET https://sandbox.coreruleset.org/backends` returns the engines, the CRS version aliases each one offers, the output formats and the control headers as JSON. It is the authoritative list; the tables on this page are a snapshot.

```bash
curl -s https://sandbox.coreruleset.org/backends | jq .
```

## Default options

It's useful to know that you can tweak the sandbox in various ways. If you don't send any `X-` headers, the sandbox will use the following defaults.

- The default backend is _Apache 2 with ModSecurity 2.9_.
- The default CRS version is `v4-lts`, the _newest release of the CRS 4 long-term support line_. Use `latest` for the newest release.
- The default Paranoia Level is 1, which is the least strict setting.
- By default, the response is the full audit log from the WAF, which is verbose and includes unnecessary information, hence why `X-Format-Output: txt-matched-rules` is useful. A browser (a client whose `Accept` header lists `text/html`) gets an HTML report instead.

## Changing options

Let's say you want to try your payload on different WAF engines or CRS versions, or like the output in a different format for automated usage. You can do this by adding the following HTTP headers to your request:

- `x-crs-version`: will pick another CRS version. Available values are the aliases `v4-lts` (default), `v3-lts` and `latest`; see the quick reference above for what each one currently resolves to. Version numbers such as `4.25.0` are not accepted.
- `x-crs-paranoia-level`: will run CRS in a given paranoia level. Available values are `1` (default), `2`, `3`, `4`.
- `x-crs-detection-paranoia-level`: sets the detection paranoia level on its own, so rules from higher levels are reported without affecting the blocking decision. Available values are `1` to `4`; it must not be lower than `x-crs-paranoia-level`.
- `x-crs-mode`: can be changed to return the http status code from the backend WAF. Default value is blocking (`On`), and can be changed using `detection` (will set engine to `DetectionOnly`). Values are case insensitive.
- `x-crs-inbound-anomaly-score-threshold`: defines the inbound anomaly score threshold. Valid values are any integer > 0, with `5` being the CRS default. ⚠️ Anything different than a positive integer will be taken as 0, so it will be ignored. This only makes sense if `blocking` mode is enabled (the default now).
- `x-crs-outbound-anomaly-score-threshold`: defines the outbound anomaly score threshold. Valid values are any integer > 0, with `4` being the CRS default.  ⚠️ Anything different than a positive integer will be taken as 0, so it will be ignored. This only makes sense if `blocking` mode is enabled (the default now).
- `x-backend` allows you to select the specific backend web server:
  - `apache` (default) will send the request to **Apache 2 + ModSecurity 2.9**.
  - `nginx` will send the request to **Nginx + ModSecurity 3**.
  - `coraza` will send the request to **Coraza WAF on Caddy**.
- `x-format-output` formats the response to your use-case (human or automation). Available values are:
  - omitted/default: the WAF's audit log is returned unmodified as JSON (HTML report for browsers)
  - `txt-matched-rules`: human-readable list of CRS rule matches, one rule per line
  - `txt-matched-rules-extended`: same but with explanation for easy inclusion in publications
  - `json-matched-rules`: JSON list of CRS rule matches with `id`, `message` and `paranoia_level`; this format is stable and will not grow new fields
  - `json-report`: JSON report with the engine, the CRS version alias and tag, the HTTP status, whether the request was `blocked`, the anomaly scores and the matched rules including the matched data and severity; new fields are added here
  - `csv-matched-rules`: CSV formatted
  - `html-matched-rules`: HTML page with a styled table of matched rules

Invalid `x-format-output` values default to `json-matched-rules`. An unsupported `x-backend` / `x-crs-version` combination (for instance `coraza` with `v3-lts`) is answered with a `400` and a JSON body listing the supported combinations.

The header names are case-insensitive.

{{% notice style="tip" icon="terminal" %}}
If you work with JSON output (either unmodified or matched rules), `jq` is a useful tool to work with the output, for example you can add `| jq .` to get a pretty-printed JSON, or use `jq` to filter and modify the output.
{{% /notice %}}

### Advanced examples

Let's say you want to send a payload to the **CRS 3.3** line and choose **Nginx + ModSecurity 3** as a backend, because this is what you are interested in. You want to get the output in JSON because you want to process the results with a script. (For now, we use `jq` to pretty-print it.)

The command would look like:

```bash
curl -H "x-backend: nginx" \
  -H "x-crs-version: v3-lts" \
  -H "x-format-output: json-matched-rules" \
  https://sandbox.coreruleset.org/?file=/etc/passwd | jq .

[
  {
    "message": "OS File Access Attempt",
    "id": "930120",
    "paranoia_level": "1"
  },
  {
    "message": "Remote Command Execution: Unix Shell Code Found",
    "id": "932160",
    "paranoia_level": "1"
  },
  {
    "message": "Inbound Anomaly Score Exceeded (Total Score: 10)",
    "id": "949110",
    "paranoia_level": "?"
  }
]
```

If you want to know more than the rule ids, `json-report` adds the verdict and the data that matched:

```bash
curl -H "x-format-output: json-report" \
  https://sandbox.coreruleset.org/?file=/etc/passwd | jq .

{
  "status": 403,
  "paranoia_level": 1,
  "anomaly_scores": {
    "inbound": {
      "blocking": 10
    }
  },
  "crs_version_tag": "v4.25.2",
  "blocked": true,
  "default_config_matched": false,
  "matched_rules": [
    {
      "data": "Matched Data: etc/passwd found within ARGS:file: /etc/passwd",
      "message": "OS File Access Attempt",
      "id": "930120",
      "severity": "CRITICAL",
      "paranoia_level": "1"
    },
    {
      "data": "Matched Data: etc/passwd found within ARGS:file: /etc/passwd",
      "message": "Remote Command Execution: Unix Shell Code Found",
      "id": "932160",
      "severity": "CRITICAL",
      "paranoia_level": "1"
    },
    {
      "message": "Inbound Anomaly Score Exceeded (Total Score: 10)",
      "id": "949110",
      "paranoia_level": "?"
    },
    {
      "message": "Anomaly Scores: (Inbound Scores: blocking=10, detection=10, per_pl=10-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=5, RCE=5, PHPI=0, HTTP=0, SESS=0, COMBINED_SCORE=10)",
      "id": "980170",
      "paranoia_level": "?"
    }
  ],
  "crs_version": "v4-lts",
  "engine": "apache"
}
```

You can also test the same payload across different WAF engines to compare detection behavior:

```bash
# Test on Coraza (Caddy-based WAF)
curl -H "x-backend: coraza" \
  -H "x-format-output: txt-matched-rules" \
  'https://sandbox.coreruleset.org/?q=<script>alert(1)</script>'
```

Let's say you are working on a vulnerability publication and want to add a paragraph to explain how CRS protects (or doesn't!) against your exploit. Then the `txt-matched-rules-extended` can be a useful format for you.

```bash
curl -H 'x-format-output: txt-matched-rules-extended' \
  https://sandbox.coreruleset.org/?file=/etc/passwd

This payload has been tested against the OWASP CRS web application firewall.
The test was executed using the apache engine and CRS version v4-lts (v4.25.2).

The payload is being detected by triggering the following rules:

930120 PL1 OS File Access Attempt
932160 PL1 Remote Command Execution: Unix Shell Code Found
949110 PL? Inbound Anomaly Score Exceeded (Total Score: 10)
980170 PL? Anomaly Scores: (Inbound Scores: blocking=10, detection=10, per_pl=10-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=5, RCE=5, PHPI=0, HTTP=0, SESS=0, COMBINED_SCORE=10)

CRS therefore detects this payload starting with paranoia level 1 and above.
```

## Capacity

- Please do not send more than 10 requests per second.
- We will try to scale in response to demand.

## Data and privacy

All requests sent to the sandbox are logged and processed by the sandbox infrastructure. **Do not send real personal data, credentials, API keys, or any sensitive information** in your requests. By using the sandbox, you acknowledge that submitted request content may be retained and analyzed by the OWASP CRS Team for the purpose of improving CRS rules and sandbox infrastructure. See the [CRS Sandbox Security Policy]({{% ref "6-7-crs-sandbox-security-policy.md" %}}) for full details.

## Architecture

The sandbox consists of various parts. An NLB (Network Load Balancer) sits in front of the frontend and distributes incoming traffic. The frontend that receives the requests runs on OpenResty (Nginx with Lua). It handles the incoming request, selects the backend running CRS based on the request headers, proxies the request to the backend, and waits for the response. Then it parses the WAF audit log and sends the matched rules back in the format chosen by the user.

```mermaid
graph LR
  Client --> NLB[NLB]
  NLB --> OpenResty[OpenResty<br>Lua routing]
  OpenResty --> WAF[WAF Backend]
  WAF --> Mirror[Mirror Backend<br>go-httpbin]
  WAF --> CRS[ModSecurity /<br>Coraza CRS]
```

There is a backend service for every engine and version. The current backends are:

| Backend | Engine | Services |
|---------|--------|----------|
| Apache + ModSecurity 2.9 | `apache` | `apache-v4-lts`, `apache-v3-lts`, `apache-latest` |
| Nginx + ModSecurity 3 | `nginx` | `nginx-v4-lts`, `nginx-v3-lts`, `nginx-latest` |
| Coraza WAF on Caddy | `coraza` | `coraza-v4-lts`, `coraza-latest` |

The backends write their JSON audit logs to a shared file system. OpenResty reads the per-transaction audit log file to extract matched rules and format the response. The logs are also copied to an S3 bucket and indexed in Elasticsearch for monitoring.

## Known issues

In some cases, the sandbox will not properly handle and finish your request.

- **Malformed HTTP requests:** The frontend, OpenResty, is itself a HTTP server which performs parsing of the incoming request. The backend servers running CRS are regular webservers such as Apache and Nginx. Either one of these may reject a malformed HTTP request with an error 400 before it is even processed by CRS. This happens for instance when you try to send an Apache 2.4.50 attack that depended on a URL encoding violation. When the frontend is the one rejecting the request, the body is a JSON error whose `source` is `sandbox-edge`; a rejection by the backend web server comes back as that server's own error page without an `X-Unique-ID`. Either way the request was not scanned by CRS.
- **ReDoS:** If your request leads to a ReDoS and makes the backend spend too much time to process a regular expression, this leads to a timeout from the backend server. The frontend will cancel the request with an error 502. If you have to wait a long time and then receive an error 502, there was likely a ReDoS situation.
- **Browsers rewrite URLs:** when you call the sandbox from a web page, the browser resolves `..` path segments, drops `#fragments` and percent-encodes most special characters before the request is sent, so the WAF may see something different from what you typed. For raw bytes use `curl` (`--path-as-is` keeps `..` segments).

## Questions and suggestions

If you have any issues with the CRS sandbox, please open a GitHub issue at [https://github.com/coreruleset/coreruleset/issues](https://github.com/coreruleset/coreruleset/issues) and we will help you as soon as possible. Include the `X-Unique-ID` of the request if you have it.

If you have suggestions for extra functionality, a GitHub issue is appreciated.
