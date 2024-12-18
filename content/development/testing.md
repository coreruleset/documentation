---
title: Testing the Rule Set
weight: 40
disableToc: false
chapter: false
---

Well, you managed to write your rule, but now want to see if if can be added to the CRS? This document should help you to test it using the same tooling the project uses for its tests.

CRS uses [go-ftw](https://github.com/coreruleset/go-ftw) to run test cases. **go-ftw** is the successor to the previously used test runner [ftw](https://github.com/coreruleset/ftw). The CRS project no longer uses **ftw** but it us still useful for running tests of older CRS versions.

## Environments

Before you start to run tests, you should set up your environment. You can use Docker to run a web server with CRS integration or use your existing environment.

### Setting up Docker containers

For testing, we use the [container images from our project](https://github.com/coreruleset/modsecurity-crs-docker). We "bind mount" the rules in the CRS Git repository to the web server container and then instruct **go-ftw** to send requests to it.

To test we need two containers: the WAF itself, and a backend, provided in this case by [Albedo](https://github.com/coreruleset/albedo). The `docker-compose.yml` in the CRS Git repository is a ready-to-run configuration for testing, to be used with the `docker compose` command.

> [!IMPORTANT]
> The supported platform is ModSecurity 2 with Apache httpd

Let's start the containers by executing the following command:

```bash
docker compose -f tests/docker-compose.yml up -d modsec2-apache
[+] Running 2/2
 ✔ backend Pulled                                                                                                                                                               2.1s 
   ✔ ff7dc8bdd3d5 Pull complete                                                                                                                                                 1.0s 
[+] Running 3/3
 ✔ Network tests_default      Created                                                                                                                                           0.0s 
 ✔ Container tests-backend-1  Started                                                                                                                                           0.2s 
 ✔ Container modsec2-apache   Started                                                                                                                                           0.2s 
```

Now let's see which containers are running now, using `docker ps`:

```bash
docker ps
CONTAINER ID   IMAGE                               COMMAND                  CREATED         STATUS                            PORTS                          NAMES
0570b291c386   owasp/modsecurity-crs:apache        "/bin/sh -c '/bin/cp…"   7 seconds ago   Up 7 seconds (health: starting)   80/tcp, 0.0.0.0:80->8080/tcp   modsec2-apache
50704d5c5762   ghcr.io/coreruleset/albedo:0.0.13   "/usr/bin/albedo --p…"   7 seconds ago   Up 7 seconds                                                     tests-backend-1
```

Excellent, our containers are running, now we can start our tests.

### Using your own environment for testing {#use-own-env}

If you have your own environment set up, you can configure that for testing. Please [follow these instructions]({{% ref "install.md#installing-a-compatible-waf-engine" %}}) to install the WAF server locally.

> [!NOTE]
> Remember: The supported platform is ModSecurity 2 with Apache httpd. If you want to run the tests against nginx, you can do that too, but nginx uses libmodsecurity3, which is not fully compatible with Apache httpd + ModSecurity 2.

If you want to run the complete test suite of CRS 4.x with **go-ftw**, you need to make some modifications to your setup. This is because the test cases for 4.x contain some extra data for responses, letting us test the `RESPONSE-*` rules too. Without the following steps these tests will fail.

To enable response handling for tests you will need to download an additional tool, [albedo](https://github.com/coreruleset/albedo). 

#### Start `albedo`

Albedo is a simple HTTP server used as a reverse-proxy backend in testing web application firewalls (WAFs). go-ftw relies on Albedo to test WAF response rules.

You can start `albedo` with this command:

```bash
./albedo -p 8085
```

As you can see the HTTP server listens on `*:8085`, you can check it using:

```bash
curl -H "Content-Type: application/json" -d '{"body":"Hello, World from albedo"}' "http://localhost:8085/reflect"
Hello, World from albedo%
```

Check for other features using the url `/capabilities` on albedo. The reflection feature is mandatory for testing response rules.

### Modify webserver's config

For the response tests you need to set up your web server as a proxy, forwarding the requests to the backend. The following is an example of such a proxy setup.

**Before you start to change your configurations, please make a backup!**

#### Apache httpd

Put this snippet into your httpd's default config (eg. `/etc/apache2/sites-enabled/000-default.conf`):

```apacheconf
  ProxyPreserveHost On
  ProxyPass / http://127.0.0.1:8000/
  ProxyPassReverse / http://127.0.0.1:8000/
  ServerName localhost
```

#### nginx

Put this snippet into the nginx default config (e.g., `/etc/nginx/conf.d/default.conf`) or replace the existing one:

```nginx
  location / {
          proxy_pass http://127.0.0.1:8000/;
          proxy_set_header Host $host;
          proxy_set_header Proxy "";
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Port $server_port;
          proxy_set_header X-Forwarded-Proto $scheme;

          proxy_http_version 1.1;
          proxy_buffering off;
          proxy_connect_timeout 60s;
          proxy_read_timeout 36000s;
          proxy_redirect off;

          proxy_pass_header Authorization;
  }
```

In both cases (Apache httpd, nginx) you have to change your `modsecurity.conf` settings. Open that file and find the directive `SecResponseBodyMimeType`. Modify the arguments:

```apacheconf
SecResponseBodyMimeType text/plain text/html text/xml application/json
```

Note, that the default value does not have the MIME type `application/json`.

In your `crs-setup.conf` you need to add these extra rules (after the rule `900990`):

```apacheconf
SecAction \
    "id:900005,\
    phase:1,\
    nolog,\
    pass,\
    ctl:ruleEngine=DetectionOnly,\
    ctl:ruleRemoveById=910000,\
    setvar:tx.blocking_paranoia_level=4,\
    setvar:tx.crs_validate_utf8_encoding=1,\
    setvar:tx.arg_name_length=100,\
    setvar:tx.arg_length=400,\
    setvar:tx.total_arg_length=64000,\
    setvar:tx.max_num_args=255,\
    setvar:tx.max_file_size=64100,\
    setvar:tx.combined_file_sizes=65535"

SecRule REQUEST_HEADERS:X-CRS-Test "@rx ^.*$" \
    "id:999999,\
    phase:1,\
    pass,\
    t:none,\
    log,\
    msg:'%{MATCHED_VAR}'"
```

Now, after restarting the web server all request will be sent to the backend. Let's start testing.

## Go-ftw

Tests are performed using [go-ftw](https://github.com/coreruleset/go-ftw). We run our test suite automatically using **go-ftw** as part of a [GitHub workflow](https://github.com/coreruleset/coreruleset/blob/{{< param crs_dev_branch >}}/.github/workflows/test.yml). You can easily reproduce that locally, on your workstation.

For that you will need:

- the CRS Git repository
- Docker compose. See [here](https://docs.docker.com/compose/install/) for installation instructions.
  OR
  [setup and use your own environment]({{% relref "#use-own-env" %}})
- your rules and tests!

{{% notice style="primary" title="Installing Go-FTW" icon="fa-solid fa-lightbulb" %}}
We strongly suggest to install a pre-compiled binary of **go-ftw** available [on GitHub](https://github.com/coreruleset/go-ftw/releases).

The binary is ready to run and does not require installation. On the releases page you will also find `.deb` and `.rpm` packages that can be used for installation on some GNU/Linux systems.

Modern versions of `go-ftw` have also a `self-update` command that will simplify updating to newer releases for you! {{% icon icon="wand-sparkles" %}}
{{% /notice %}}

You can also install pre-compiled binaries by using `go install`, if you have a **Go** environment:

```bash
go install github.com/coreruleset/go-ftw@latest
```

This will install the binary into your `$HOME/go/bin` directory. To compile **go-ftw** from source, run the following commands:

```bash
git clone https://github.com/coreruleset/go-ftw.git
cd go-ftw
go build
```

This will build the binary in the **go-ftw** repository.

Now create a configuration file. Because Apache httpd and nginx use different log file paths, and, perhaps, different ports, you may want to create two different configuration files for **go-ftw**. For details please read [go-ftw's documentation](https://github.com/coreruleset/go-ftw#yaml-config-file).

Example `.ftw.nginx.yaml` file for nginx:

```yaml
logfile: /var/log/nginx/error.log
logmarkerheadername: X-CRS-TEST
testoverride:
  input:
    dest_addr: "127.0.0.1"
    port: 8080
```

Example file `.ftw.apache.yaml` for Apache httpd:

```yaml
logfile: /var/log/apache2/error.log
logmarkerheadername: X-CRS-TEST
testoverride:
  input:
    dest_addr: "127.0.0.1"
    port: 80
```

Please verify that these settings are correct for your setup, especially the `port` values.

### Running the test suite

Execute the following command to run the CRS test suite with **go-ftw** against Apache httpd:

> [!WARNING]
> ⚠️  If go-ftw is installed from a pre-compiled binary, then you might have to use `ftw` instead of the `go-ftw` command.

```bash
./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/
🛠️  Starting tests!
🚀 Running go-ftw!
👉 executing tests in file 911100.yaml
	running 911100-1: ✔ passed in 239.699575ms (RTT 126.721984ms)
	running 911100-2: ✔ passed in 63.339213ms (RTT 69.998361ms)
	running 911100-3: ✔ passed in 64.87875ms (RTT 71.368241ms)
	running 911100-4: ✔ passed in 77.823772ms (RTT 81.059904ms)
	running 911100-5: ✔ passed in 64.451749ms (RTT 70.403898ms)
	running 911100-6: ✔ passed in 67.774327ms (RTT 73.803885ms)
	running 911100-7: ✔ passed in 65.528094ms (RTT 72.64316ms)
	running 911100-8: ✔ passed in 66.129563ms (RTT 73.198992ms)
👉 executing tests in file 913100.yaml
	running 913100-1: ✔ passed in 71.242549ms (RTT 76.803619ms)
	running 913100-2: ✔ passed in 69.999667ms (RTT 76.617714ms)
	running 913100-3: ✔ passed in 70.200211ms (RTT 76.92281ms)
	running 913100-4: ✔ passed in 65.856005ms (RTT 73.328341ms)
	running 913100-5: ✔ passed in 66.986859ms (RTT 73.494356ms)
  ...
```

To run the test suite against nginx, execute the following:

```bash
./go-ftw run --config .ftw.nginx.yaml -d ../coreruleset/tests/regression/tests/
🛠️  Starting tests!
🚀 Running go-ftw!
👉 executing tests in file 911100.yaml
	running 911100-1: ✔ passed in 851.460335ms (RTT 292.802335ms)
	running 911100-2: ✔ passed in 53.748811ms (RTT 66.798867ms)
	running 911100-3: ✔ passed in 49.237535ms (RTT 67.964411ms)
	running 911100-4: ✔ passed in 194.935023ms (RTT 202.414171ms)
	running 911100-5: ✔ passed in 52.905305ms (RTT 66.254034ms)
	running 911100-6: ✔ passed in 52.597784ms (RTT 68.58854ms)
	running 911100-7: ✔ passed in 51.996881ms (RTT 67.496534ms)
	running 911100-8: ✔ passed in 50.804143ms (RTT 67.589557ms)
👉 executing tests in file 913100.yaml
	running 913100-1: ✔ passed in 276.383507ms (RTT 85.436758ms)
	running 913100-2: ✔ passed in 86.682684ms (RTT 69.89541ms)
  ...
```

If you want to run only one test, or a group of tests, you can specify that using the "include" option `-i` (or `--include`). This option takes a regular expression:

```bash
./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$"
```

In the above case only the test case `955100-1` will be run.

If you need to see more verbose output (e.g., to look at the requests and responses sent and received by **go-ftw**) you can use the `--debug` or `--trace` options:

```bash
./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$" --trace
```

```bash
./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$" --debug
```

Please note again that `libmodsecurity3` is **not fully compatible** with ModSecurity 2, some tests can fail. If you want to ignore them, you can put the tests into a list in your config:

```yaml
testoverride:
  input:
    dest_addr: "127.0.0.1"
    port: 8080
  ignore:
    # text comes from our friends at https://github.com/digitalwave/ftwrunner
    '941190-3$': 'known MSC bug - PR #2023 (Cookie without value)'
    '941330-1$': 'know MSC bug - #2148 (double escape)'
    ...
```

For more information and examples, please check the [go-ftw documentation](https://github.com/coreruleset/go-ftw#example-usage).

**Also please don't forget to roll back the modifications from this guide to your WAF configuration after you're done testing!**

## Additional tips

- ⚠️ If your test is not matching, you can take a peek at the `modsec_audit.log` file, using: `sudo tail -200 tests/logs/modsec2-apache/modsec_audit.log`
- 🔧 If you need to write a test that cannot be written using text (e.g. binary content), we prefer using `encoded_request` in the test, using base64 encoding

## Summary

Tests are a core functionality in our ruleset. So whenever you write a rule, try to add some positive and negative tests so we won't have surprises in the future.

Happy testing! 🎉
