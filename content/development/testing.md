---
title: Testing the Rule Set
weight: 40
disableToc: false
chapter: false
---

# Testing for rule developers

Well, you managed to write your rule, but now want to see if if can be added to the CRS? This document should help you to test it using the same tooling the project uses for its tests.

CRS uses [go-ftw](https://github.com/coreruleset/go-ftw) to run test cases. **go-ftw** is the successor to the previously used test runner [ftw](https://github.com/coreruleset/ftw). The CRS project no longer uses **ftw** but it us still useful for running tests of older CRS versions.

## Environments

Before you start to run tests, you should set up your environment. You can use Docker to run a web server with CRS integration or use your existing environment.

### Setting up Docker containers

For testing, we use the [container images from our project](https://github.com/coreruleset/modsecurity-crs-docker). We "bind mount" the rules in the CRS Git repository to the web server container and then instruct **go-ftw** to send requests to it.

To test we need two containers: the WAF itself, and a backend, provided in this case by [Albedo](https://github.com/coreruleset/albedo). The `docker-compose.yml` in the CRS Git repository is a ready-to-run configuration for testing, to be used with the `docker compose` command.

-> The supported platform is ModSecurity 2 with Apache httpd

Let's start the containers by executing the following command:
```bash
❯ docker compose -f tests/docker-compose.yml up -d modsec2-apache
[+] Running 2/2
 ✔ backend Pulled                                                                                                                                                               2.1s 
   ✔ ff7dc8bdd3d5 Pull complete                                                                                                                                                 1.0s 
[+] Running 3/3
 ✔ Network tests_default      Created                                                                                                                                           0.0s 
 ✔ Container tests-backend-1  Started                                                                                                                                           0.2s 
 ✔ Container modsec2-apache   Started                                                                                                                                           0.2s 
❯ docker ps
CONTAINER ID   IMAGE                               COMMAND                  CREATED         STATUS                            PORTS                          NAMES
0570b291c386   owasp/modsecurity-crs:apache        "/bin/sh -c '/bin/cp…"   7 seconds ago   Up 7 seconds (health: starting)   80/tcp, 0.0.0.0:80->8080/tcp   modsec2-apache
50704d5c5762   ghcr.io/coreruleset/albedo:0.0.13   "/usr/bin/albedo --p…"   7 seconds ago   Up 7 seconds                                                     tests-backend-1
```

Excellent, our containers are running, now we can start our tests.

### Using your own environment for testing {#use-own-env}

If you have your own environment set up, you can configure that for testing. Please [follow these instructions]({{% ref "install.md#installing-a-compatible-waf-engine" %}}) to install the WAF server locally.

-> The supported platform is ModSecurity 2 with Apache httpd. If you want to run the tests against nginx, you can do that too, but nginx uses libmodsecurity3, which is not fully compatible with Apache httpd + ModSecurity 2.

If you want to run the complete test suite of CRS 4.0 with **go-ftw**, you need to make some modifications to your setup. This is because the test cases for 4.0 contain some extra data for responses, letting us test the `RESPONSE-*` rules too. Without the following steps these tests will fail.

<!-- FIXME: @airween: how do you want to add Albedo here? -->
To enable response handling for tests you will need the following additional packages: `python3-gunicorn`, `gunicorn` and `python3-httpbin`.

#### Start `httpbin`

[`httpbin`](https://httpbin.org/) is a simple HTTP request & response service. You send a request, and it sends it back in the response.

You can start `httpbin` with this command:

```bash
/usr/bin/python3 /usr/bin/gunicorn --error-logfile - --access-logfile - --access-logformat "%(h)s %(t)s %(r)s %(s)s Content-Type: %({Content-Type}i)s" httpbin:app
[2023-12-14 15:59:53 +0100] [4012] [INFO] Starting gunicorn 20.1.0
[2023-12-14 15:59:53 +0100] [4012] [INFO] Listening at: http://127.0.0.1:8000 (4012)
[2023-12-14 15:59:53 +0100] [4012] [INFO] Using worker: sync
[2023-12-14 15:59:53 +0100] [4013] [INFO] Booting worker with pid: 4013
```

As you can see the HTTP server listens on 127.0.0.1:8000, you can check it:

```bash
$ curl -X POST -H "Content-Type: application/json" -d '{"foo":"bar"}' "http://localhost:8000/anything"
{
  "args": {},
  "data": "{\"foo\":\"bar\"}",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Content-Length": "13",
    "Content-Type": "application/json",
    "Host": "localhost:8000",
    "User-Agent": "curl/8.4.0"
  },
  "json": {
    "foo": "bar"
  },
  "method": "POST",
  "origin": "127.0.0.1",
  "url": "http://localhost:8000/anything"
}
```

As you can see, the response's `data` field contains your request data. This feature is mandatory for testing response rules.

### Modify webserver's config

For the response tests you need to set up your web server as a proxy, forwarding the requests to the backend. The following is an example of such a proxy setup.

**Before you start to change your configurations, please make a backup!**

#### Apache httpd

Put this snippet into your httpd's default config (eg. `/etc/apache2/sites-enabled/000-default.conf`):

```
        ProxyPreserveHost On
        ProxyPass / http://127.0.0.1:8000/
        ProxyPassReverse / http://127.0.0.1:8000/
        ServerName localhost
```

#### nginx

Put this snippet into the nginx default config (e.g., `/etc/nginx/conf.d/default.conf`) or replace the existing one:

```
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

```
SecResponseBodyMimeType text/plain text/html text/xml application/json
```

Note, that the default value does not have the MIME type `application/json`.

In your `crs-setup.conf` you need to add these extra rules (after the rule `900990`):

```
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
- Docker (modern versions of docker already include the `compose` command, if you are running an older version you also need to have `docker-compose` installed)
  OR
  [your own environment]({{% relref "#use-own-env" %}})
- your rules and tests!

You can download pre-compiled binaries of **go-ftw** or build from source (requires you to have a **Go** environment). The pre-compiled binaries are available [on GitHub](https://github.com/coreruleset/go-ftw/releases). The binaries are ready to run and do not require installation.

You can also install pre-compiled binaries by using `go install`, if you have a **Go** environment:

```bash
$ go install github.com/coreruleset/go-ftw@latest
```

This will install the binary into your `$HOME/go/bin` directory. To compile **go-ftw** from source, run the following commands:

```bash
$ git clone https://github.com/coreruleset/go-ftw.git
$ cd go-ftw
$ go build
```

This will build the binary in the **go-ftw** repository.

Now create a configuration file. Because Apache httpd and nginx use different log file paths, and, perhaps, different ports, you may want to create two different configuration files for **go-ftw**. For details please read [go-ftw's documentation](https://github.com/coreruleset/go-ftw#yaml-config-file).

Example for nginx:

```bash
$ cat .ftw.nginx.yaml
logfile: /var/log/nginx/error.log
logmarkerheadername: X-CRS-TEST
testoverride:
  input:
    dest_addr: "127.0.0.1"
    port: 8080
```

Example for Apache httpd:

```bash
$ cat .ftw.apache.yaml
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

⚠️  If go-ftw is installed from a pre-compiled binary, then you might have to use `ftw` instead of the `go-ftw` command.

```bash
$ ./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/
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
$ ./go-ftw run --config .ftw.nginx.yaml -d ../coreruleset/tests/regression/tests/
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
$ ./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$"
```

In the above case only the test case `955100-1` will be run.

If you need to see more verbose output (e.g., to look at the requests and responses sent and received by **go-ftw**) you can use the `--debug` or `--trace` options:

```bash
$ ./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$" --trace
```


```bash
$ ./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$" --debug
```

Please note again that `libmodsecurity3` is **not fully compatible** with ModSecurity 2, some tests can fail. If you want to ignore them, you can put the tests into a list in your config:

```
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

## FTW (deprecated)

[ftw](https://github.com/coreruleset/ftw) is our legacy test runner, and is **deprecated** and no longer used for tests after CRS v3.2. Refer to this [GitHub workflow](https://github.com/coreruleset/coreruleset/blob/v3.2/dev/.travis.yml#L52) if you need to use the old **ftw** Python version. You can easily reproduce that locally, on your workstation.

For that you will need:

- the coreruleset git repository
- docker and docker-compose (modern versions of docker already include compose functionality)
- python3
- your rules and tests!

### Setting up the basic environment

I normally use [pipenv](https://docs.pipenv.org/) whenever Python is involved. It will give you both isolation and dependencies at once. But you can use basic pip and virtualenv and the result will be the same.

For installing the python tooling, just use:

```bash
❯ pipenv install -r tests/regression/requirements.txt
Creating a virtualenv for this project...
Pipfile: /private/tmp/coreruleset/Pipfile
Using /usr/local/bin/python3 (3.9.5) to create virtualenv...
⠧ Creating virtual environment...created virtual environment CPython3.9.5.final.0-64 in 392ms
  creator CPython3Posix(dest=/Users/fzipitria/.local/share/virtualenvs/coreruleset-UNJnkEXP, clear=False, global=False)
  seeder FromAppData(download=False, pip=bundle, setuptools=bundle, wheel=bundle, via=copy, app_data_dir=/Users/fzipitria/Library/Application Support/virtualenv)
    added seed packages: pip==21.0.1, setuptools==56.0.0, wheel==0.36.2
  activators BashActivator,CShellActivator,FishActivator,PowerShellActivator,PythonActivator,XonshActivator

✔ Successfully created virtual environment!
Virtualenv location: /Users/fzipitria/.local/share/virtualenvs/coreruleset-UNJnkEXP
Creating a Pipfile for this project...
Requirements file provided! Importing into Pipfile...
Pipfile.lock not found, creating...
Locking [dev-packages] dependencies...
Locking [packages] dependencies...
Building requirements...
Resolving dependencies...
✔ Success!
Updated Pipfile.lock (02e6ae)!
Installing dependencies from Pipfile.lock (02e6ae)...
  🐍   ▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉ 17/17 — 00:00:28
To activate this project's virtualenv, run pipenv shell.
Alternatively, run a command inside the virtualenv with pipenv run.
```

Now we are ready to start running tests.

### Running the test suite

The test suite will be run by the tool `ftw`, now that we started our containers.

If you used the `pipenv` tool for installing the module, now is time to enter the shell:
```bash
❯ py.test -vs --tb=short tests/regression/CRS_Tests.py --config=modsec2-apache --ruledir_recurse=./tests/regression/tests
============================================================================== test session starts ===============================================================================
platform darwin -- Python 3.9.5, pytest-4.6.0, py-1.10.0, pluggy-0.13.1 -- /Users/fzipitria/.local/share/virtualenvs/coreruleset-bLfwOI0B/bin/python
cachedir: .pytest_cache
rootdir: /Users/fzipitria/Workspace/OWASP/coreruleset
plugins: ftw-1.2.4
collected 2468 items

tests/regression/CRS_Tests.py::test_crs[ruleset0-933210.yaml -- 933210-1] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset1-933210.yaml -- 933210-2] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset2-933210.yaml -- 933210-3] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset3-933210.yaml -- 933210-4] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset4-933210.yaml -- 933210-5] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset5-933210.yaml -- 933210-6] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset6-933210.yaml -- 933210-7] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset7-933210.yaml -- 933210-8] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset8-933210.yaml -- 933210-9] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset9-933210.yaml -- 933210-10] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset10-933210.yaml -- 933210-11] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset11-933210.yaml -- 933210-12] PASSED
tests/regression/CRS_Tests.py::test_crs[ruleset12-933210.yaml -- 933210-13] PASSED
...
```

Couple notes here:
- using `--ruledir_recurse=./tests/regression/tests` will walk over all the tests defined below that directory
- you can test your specific file using `--rule=./mytest.yaml`

```bash
❯ py.test -vs --tb=short tests/regression/CRS_Tests.py --config=modsec2-apache --rule=./mytest.yaml
============================================================================== test session starts ===============================================================================
platform darwin -- Python 3.9.5, pytest-4.6.0, py-1.10.0, pluggy-0.13.1 -- /Users/fzipitria/.local/share/virtualenvs/coreruleset-bLfwOI0B/bin/python
cachedir: .pytest_cache
rootdir: /Users/fzipitria/Workspace/OWASP/coreruleset
plugins: ftw-1.2.4
collected 1 item

tests/regression/CRS_Tests.py::test_crs[ruleset0-mytest.yaml -- mytest-1] PASSED

================================================================================ warnings summary ================================================================================
/Users/fzipitria/.local/share/virtualenvs/coreruleset-bLfwOI0B/lib/python3.9/site-packages/yaml/constructor.py:126
  /Users/fzipitria/.local/share/virtualenvs/coreruleset-bLfwOI0B/lib/python3.9/site-packages/yaml/constructor.py:126: DeprecationWarning: Using or importing the ABCs from 'collections' instead of from 'collections.abc' is deprecated since Python 3.3, and in 3.10 it will stop working
    if not isinstance(key, collections.Hashable):

-- Docs: https://docs.pytest.org/en/latest/warnings.html
====================================================================== 1 passed, 1 warnings in 0.36 seconds ======================================================================
```

That's it!

## Additional tips

⚠️ If your test is not matching, you can take a peek at the `modsec_audit.log` file, using: `sudo tail -200 tests/logs/modsec2-apache/modsec_audit.log`

🔧 If you need to write a test that cannot be written using text (e.g. binary content), we prefer using `encoded_request` in the test, using base64 encoding

## Summary

Tests are a core functionality in our ruleset. So whenever you write a rule, try to add some positive and negative tests so we won't have surprises in the future.

Happy testing! 🎉 
