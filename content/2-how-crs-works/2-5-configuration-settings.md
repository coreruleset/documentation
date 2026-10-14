---
title: Configuration Settings
weight: 25
disableToc: false
chapter: false
---

> CRS is configured through `crs-setup.conf`. This page lists every setting in that file, its default, and when to change it. It is a reference; the concepts behind the main settings are explained in the other pages of this chapter.

## How Settings Work

The file `crs-setup.conf.example` ships with every release. Copy it to `crs-setup.conf` and include it *before* the rule files, as described in the [installation guide]({{% ref "1-1-crs-installation.md" %}}).

Almost every setting is a `SecAction` rule with an ID in the `900xxx` range that sets a transaction variable with `setvar`. Most of these rules are commented out: the rule file `REQUEST-901-INITIALIZATION.conf` applies the default value whenever a variable has not been set. To change a setting, uncomment its rule in `crs-setup.conf` and edit the value.

{{% notice note %}}
`crs-setup.conf` configures CRS only. Engine settings such as `SecRuleEngine`, `SecRequestBodyAccess`, or the audit log live in the engine's own configuration file (`modsecurity.conf` or `coraza.conf`), which must be loaded first.
{{% /notice %}}

{{% notice style="tip" icon="upload" %}}
When upgrading CRS, diff your `crs-setup.conf` against the new `crs-setup.conf.example`. New settings are added over time and defaults change. Rule `900990` records the setup file version in `tx.crs_setup_version`. If the variable is missing, rule 901001 denies every request with a 500 status, which is how CRS detects a missing or wrongly ordered setup file.
{{% /notice %}}

## Default Actions

Plain `SecDefaultAction` directives at the top of the file set the engine behavior for rules that don't specify their own. Since CRS 4.28.0 a default is set for every phase, so phases 3 to 5 (response and logging) log the same way as the request phases:

```apache
SecDefaultAction "phase:1,log,auditlog,pass"
SecDefaultAction "phase:2,log,auditlog,pass"
SecDefaultAction "phase:3,log,auditlog,pass"
SecDefaultAction "phase:4,log,auditlog,pass"
SecDefaultAction "phase:5,log,auditlog,pass"
```

The default `pass` action is what makes anomaly scoring work: individual rules only add to the score and the blocking decision is taken at the end of the phase. Replace `log` with `nolog` to write alerts only to the audit log. Changing `pass` to `deny` switches to [self-contained mode]({{% ref "5-1-self-contained-mode.md" %}}), which is discouraged.

## Anomaly Scoring

See [anomaly scoring]({{% ref "2-1-anomaly_scoring" %}}) for the concepts.

| Rule | Variable | Default | Purpose |
|------|----------|---------|---------|
| 900100 | `tx.critical_anomaly_score` | 5 | Score added by a critical severity rule |
| 900100 | `tx.error_anomaly_score` | 4 | Score added by an error severity rule |
| 900100 | `tx.warning_anomaly_score` | 3 | Score added by a warning severity rule |
| 900100 | `tx.notice_anomaly_score` | 2 | Score added by a notice severity rule |
| 900110 | `tx.inbound_anomaly_score_threshold` | 5 | Request is blocked when its score reaches this value |
| 900110 | `tx.outbound_anomaly_score_threshold` | 4 | Response is blocked when its score reaches this value |
| 900115 | `tx.reporting_level` | 4 | Verbosity of the phase 5 anomaly score reporting rules, 0 (off) to 5 (every request) |
| 900120 | `tx.early_blocking` | 0 | Set to 1 to block at the end of phase 1 or 3 instead of waiting for phase 2 or 4 |

## Paranoia Levels

See [paranoia levels]({{% ref "2-2-paranoia_levels.md" %}}) for the concepts.

| Rule | Variable | Default | Purpose |
|------|----------|---------|---------|
| 900000 | `tx.blocking_paranoia_level` | 1 | Rules up to this level contribute to the blocking score |
| 900001 | `tx.detection_paranoia_level` | same as blocking | Rules up to this level run and are logged, but only contribute to a separate detection score |

## HTTP Policy

These settings feed the protocol enforcement rules in `REQUEST-920-PROTOCOL-ENFORCEMENT.conf`. Lists use a delimiter around each entry so that the `@within` operator matches exactly: pipes for content types and charsets, slashes for file extensions and headers, spaces for methods and versions.

| Rule | Variable | Default | Purpose |
|------|----------|---------|---------|
| 900200 | `tx.allowed_methods` | `GET HEAD POST OPTIONS` | HTTP methods accepted by rule 911100 |
| 900210 | `tx.allow_method_override_parameter` | 0 | Set to 1 to allow the `_method` request parameter used by some frameworks to override the HTTP method. Rule 920650 blocks it at paranoia level 2 and above |
| 900220 | `tx.allowed_request_content_type` | see below | Request content types accepted by rule 920420 |
| 900230 | `tx.allowed_http_versions` | `HTTP/1.0 HTTP/1.1 HTTP/2 HTTP/2.0 HTTP/3 HTTP/3.0` | Protocol versions accepted by rule 920430. HTTP/0.9 is no longer supported |
| 900240 | `tx.restricted_extensions` | long list | File extensions blocked by rule 920440: backups, configuration files, keys, logs, shell scripts, and similar |
| 900250 | `tx.restricted_headers_basic` | see below | Request headers blocked by rule 920450 at paranoia level 1 |
| 900255 | `tx.restricted_headers_extended` | `/accept-charset/` | Additional headers blocked by rule 920451 at paranoia level 2 |
| 900280 | `tx.allowed_request_content_type_charset` | `utf-8`, `iso-8859-1`, `iso-8859-15`, `windows-1252` | Charsets accepted in the `Content-Type` header by rule 920480 |

### Allowed Content Types

The default list is:

```
|application/x-www-form-urlencoded| |multipart/form-data| |text/xml| |application/xml| |application/soap+xml| |application/json|
```

In addition, two rules in `REQUEST-901-INITIALIZATION.conf` extend this list at runtime since CRS 4.30.0, and switch on the JSON body processor in the same rule so there is no bypass risk:

- **Rule 901370** allows any `application/*+json` type (RFC 6839 structured syntax suffix), for example `application/ld+json`, `application/problem+json`, or `application/vnd.api+json`.
- **Rule 901360** allows the AWS types `application/x-amz-json-1.0` and `application/x-amz-json-1.1`.

To turn either off, remove the rule with `ctl:ruleRemoveById` the same way as any other CRS rule. Content types without a corresponding body processor, such as `text/plain` or `application/octet-stream`, must never be added to the list without also forcing a body processor; see example 9 in [false positives and tuning]({{% ref "2-3-false-positives-and-tuning.md" %}}).

### Restricted Headers

The default basic list blocks headers that let a client alter how the request is processed: `content-encoding`, `proxy`, `lock-token`, `content-range`, `if`, `x-http-method-override`, `x-http-method`, `x-method-override`, `x-middleware-subrequest`, and `expect`. The `expect` entry blocks `Expect`-based request smuggling. .NET's `HttpWebRequest` sends this header by default; set `ServicePointManager.Expect100Continue` to `false` in the client if that is a problem.

## Request Body Processing

| Rule | Variable | Default | Purpose |
|------|----------|---------|---------|
| 900010 | `tx.enforce_bodyproc_urlencoded` | 0 | Set to 1 to force the URLENCODED body processor on requests whose content type did not activate any processor. Closes a bypass at the cost of parsing bodies that may not be form data |
| 900950 | `tx.crs_validate_utf8_encoding` | 1 | Validates that request contents are valid UTF-8 (rule 920250). Enabled by default since CRS 4.28.0. Set to 0 if your site uses a different encoding, otherwise expect false positives |

## Argument and Upload Limits

Enforced by rules 920360 to 920410 at paranoia level 1.

| Rule | Variable | Default | Purpose |
|------|----------|---------|---------|
| 900300 | `tx.max_num_args` | 255 | Maximum number of request arguments |
| 900310 | `tx.arg_name_length` | 100 | Maximum length of an argument name |
| 900320 | `tx.arg_length` | 400 | Maximum length of an argument value |
| 900330 | `tx.total_arg_length` | 64000 | Maximum combined length of all arguments |
| 900340 | `tx.max_file_size` | 1048576 | Maximum size of a single uploaded file in bytes |
| 900350 | `tx.combined_file_sizes` | 1048576 | Maximum combined size of all uploaded files in bytes |

## Other Settings

| Rule | Variable | Default | Purpose |
|------|----------|---------|---------|
| 900130 | `tx.enable_default_collections` | 0 | Set to 1 to initialize the Global and IP collections used by plugins such as DoS protection. Core rules don't need them |
| 900400 | `tx.sampling_percentage` | 100 | Percentage of requests inspected by CRS, see [sampling mode]({{% ref "2-4-sampling_mode.md" %}}) |
| 900500 | `tx.crs_skip_response_analysis` | 0 | Set to 1 to skip all response rules (phases 3 and 4). See the response filter denial of service warning in the [installation guide]({{% ref "1-1-crs-installation.md" %}}) |
| 900990 | `tx.crs_setup_version` | release number | Set unconditionally. Rule 901001 denies all requests when it is missing |
