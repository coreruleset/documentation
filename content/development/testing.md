---
title: Testing the Rule Set
weight: 40
disableToc: false
chapter: false
---

# Testing for rule developers

Well, you managed to write your rule, but now want to see if if can be added to the CRS? This document should help you to test it using the same tooling the project uses for its tests.

CRS has two kind of types of test tools. Since the version 4.0 we use [go-ftw](https://github.com/coreruleset/go-ftw), this is the new method. The "old" one is the "classic" [ftw](https://github.com/coreruleset/ftw). This is a deprecated method, but it us useful for older version of CRS.

## Environments

Before you start to run tests, you should set up your environment. You can use a Docker image, or if you have an own instance, you can use that one.

### Setting up Docker containers

For testing, we use the [docker images from our project](https://github.com/coreruleset/modsecurity-crs-docker). That way we can easily use the base containers. But, we "bind mount" the rules in the git repository. So that will allow you to easily test any rules you want inside the containers.

To test we need two containers: the WAF itself, and a backend provided by the http://httpbin.org project. That is we we use `docker-compose`, so we can run and connect them easily.

-> The supported platform is modsecurity 2 with Apache

Let's start the containers using:
```bash
❯ docker-compose -f tests/docker-compose.yml up -d modsec2-apache
Docker Compose is now in the Docker CLI, try `docker compose up`

Creating network "tests_default" with the default driver
Creating tests_backend_1 ... done
Creating modsec2-apache  ... done
❯ docker ps
CONTAINER ID   IMAGE                              COMMAND                  CREATED          STATUS         PORTS                               NAMES
785a6f6a3cb6   owasp/modsecurity-crs:3.3-apache   "/docker-entrypoint.…"   7 seconds ago    Up 3 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp   modsec2-apache
bb8d5a7f256d   kennethreitz/httpbin               "gunicorn -b 0.0.0.0…"   10 seconds ago   Up 7 seconds   80/tcp                              tests_backend_1
```

Excellent, our containers are running, now we can start our tests.

### Using your own instance

If you have an own installed instance, you can configure that for testing. If you don't have, but have a Debian or Ubuntu server, you can set up [Digitalwave's](https://modsecurity.digitalwave.hu) repository for supported distributions. There you can follow the instructions how to configure your WAF.

-> The supported platform is modsecurity 2 with Apache here too. If you want to run the tests against Nginx, you can do that too, but Nginx uses libmodsecurity3, which is not fully compatible with Apache + mod_security2.

If you want to run tests against CRS 4.0 with **go-ftw**, you need to make some modifications on your setup. This is because the test cases for 4.0 contains some extra data for responses, therefore you can check the `RESPONSE-*` rules too. Without this step these tests will be failed.

For this feature, beside the configured WAF you need some other packages: `python3-gunicorn`, `gunicorn` and `python3-httpbin`.

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

As you can see, the response's `data` field contains your request data, this is necessary for testing response rules.

### Modify webserver's config

For the response's test you need to set up your webserver as a proxy, which sends the requests to `httpbin`. Here are the examples.

**Before you start to change your configurations, please make a backup!**

#### Apache

Put this snippet into your httpd's default config:

```
        ProxyPreserveHost On
        ProxyPass / http://127.0.0.1:8000/
        ProxyPassReverse / http://127.0.0.1:8000/
        ServerName localhost
```

#### Nginx

Put this snippet into your httpd's default config or replace the existing one:

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

In both cases (Apache2, Nginx) you have to change your `modsecurity.conf` settings. Open that file and find the directive `SecResponseBodyMimeType`. Modify the arguments:

```
SecResponseBodyMimeType text/plain text/html text/xml application/json
```

Note, that the default value does not have the mime type `application/json`.

In your `crs-setup.conf` you need to add these extra rules (after the rule `900990`):

```
SecAction
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

Now after the restart all request will send to `httpbin`. Let's start testing.

## Go-ftw

Tests are performed using a golang tool called [go-ftw](https://github.com/coreruleset/go-ftw). We run them using a [GitHub actions pipeline](https://github.com/coreruleset/coreruleset/blob/{{< param crs_dev_branch >}}/.github/workflows/test.yml). You can easily reproduce that locally, in your workstation.

For that you will need:

- the coreruleset git repository
- docker and docker-compose (modern versions of docker already include compose functionality)
  OR
  an own instance (see above installation steps)
- golang compiler
- your rules and tests!

You can download the pre-compiled version or build your own instance. Precompiled versions are [here](https://github.com/coreruleset/go-ftw/releases). Just download it and you can use that.

If you want to build one, you can type:

```bash
$ go install github.com/coreruleset/go-ftw@latest
```

This will build the binary into your `$HOME/go/bin` directory. Other option:

```bash
$ git clone https://github.com/coreruleset/go-ftw.git
$ cd go-ftw
$ go build .
```

This will build the binary into your source directory.

Now create a configuration file. Because the two webservers uses different log files, and - perhaps - different ports, you can create two different config files.

You can use this for Nginx:

```bash
$ cat .ftw.nginx.yaml
logfile: /var/log/nginx/error.log
logmarkerheadername: X-CRS-TEST
testoverride:
  input:
    dest_addr: "127.0.0.1"
    port: 8080
mode: "default"
```

and this one for Apache:

```bash
$ cat .ftw.apache.yaml
logfile: /var/log/apache2/error.log
logmarkerheadername: X-CRS-TEST
testoverride:
  input:
    dest_addr: "127.0.0.1"
    port: 80
mode: "default"
```

Please check your `port` value and other settings, those can be different.

### Running the test suite

The test suite will be run by the tool `go-ftw`.

Here is how you can run tests:

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

or you can use your Nginx configuration file:

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

If you want to run only one test, or a group of tests, you can include only that one(s) with option `-i`:

```bash
$ ./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$"
```

In this case only the test case `955100-1` test will run.

If you want to see how looks like the request, response and log lines, you can pass the option `--trace`:

```bash
$ ./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$" --trace
```

or `--debug`

```bash
$ ./go-ftw run --config .ftw.apache.yaml -d ../coreruleset/tests/regression/tests/ -i "955100-1$" --debug
```

Please note again that `libmodsecurity3` is **not fully compatible** with `mod_security2`, some tests can be failed. If you want to ignore them, you can put the tests onto a list in your config:

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

For more information and examples, please check the [go-ftw](https://github.com/coreruleset/go-ftw#example-usage)'s documentation.

## Ftw

In this case tests are performed using a Python tool called [ftw](https://github.com/coreruleset/ftw). We run them using the older versions of our [GitHub actions pipeline](https://github.com/coreruleset/coreruleset/blob/v3.3/dev/.github/workflows/test.yml). You can easily reproduce that locally, in your workstation.

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
