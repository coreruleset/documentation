---
title: Testing the Rule Set
weight: 40
disableToc: false
chapter: false
---

# Testing for rule developers

Well, you managed to write your rule, but now want to see if if can be added to the CRS? This document should help you to test it using the same tooling the project uses for its tests.

Tests are performed using a Python tool called [ftw](https://github.com/coreruleset/ftw). We run them using a [GitHub actions pipeline](https://github.com/coreruleset/coreruleset/blob/{{< param crs_dev_branch >}}/dev/.github/workflows/test.yml). You can easily reproduce that locally, in your workstation.

For that you will need:

- the coreruleset git repository
- docker and docker-compose (modern versions of docker already include compose functionality)
- python3
- your rules and tests!

## Setting up the basic environment

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

## Start the containers

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

## Running the test suite

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
