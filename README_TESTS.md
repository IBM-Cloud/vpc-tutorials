# Automated tests

This project uses Travis CI to run automated tests. The Travis pipeline is driven by [.travis.yml](.travis.yml).

## What does .travis.yml contain?

### Build only on master

For every commit, pull request, new branch, Travis will run the build. However in the `.travis.yml`, we restrict the test execution to the `master` branch.

### A set of environment variables used by all tests is defined

```yml
env:
  global:
    - TEST_VPC_NAME=automated-tests-do-not-delete-us-south
    - RESOURCE_GROUP=automated-tests
    - REGION=us-south
    ...
```

* `TEST_VPC_NAME` is the name of the VPC created for the test - so far all tests need only one VPC so the approach works.

### The tests to be executed

```yml
  matrix:
    - TARGET_GENERATION=1 SCENARIO=cleanup-initial TEST=tests/teardown.sh
    - TERRAFORM_VERSION=latest TARGET_GENERATION=1 SCENARIO=vpc-one-vsi TEST=tests/vpc-one-vsi/create-with-terraform.sh
    - TARGET_GENERATION=1 SCENARIO=cleanup-vpc-public-app-private-backend TEST=tests/teardown.sh
    - TARGET_GENERATION=1 SCENARIO=vpc-site2site-vpn TEST=tests/vpc-site2site-vpn/create.sh TEARDOWN=tests/vpc-site2site-vpn/teardown.sh
```

The matrix defines the jobs that will be executed as part of the build. Jobs run independently. The Travis build is configured to run one job at a time.

For one job:
* `TARGET_GENERATION` defines which generation of compute to use (1 or 2).
* `TERRAFORM_VERSION` defines which version of Terraform to use. The default value is `0.11.14` and to use the latest version set to `latest`.
* `SCENARIO` gives the name of the test, must match the folder name. _Plan is to use this to later only re-run the tests with modified files by comparing to the scenario name._
* `TEST` points to the executable script to run, relative to the checkout directory.
* `TEARDOWN` is optional and points an executable script that will be run one `TEST` completes (with success or failure). Typically used to clean up resources created during the test.

The matrix ends up being a succession of _clean_, _test_, _clean_, _test_, _clean_ , ... The special `cleanup-` jobs use `tests/teardown.sh` and in turn `vpc-cleanup.sh` to destroy the VPC `TEST_VPC_NAME` between two test jobs, ensuring a clean state for the next step.

### Tests run within the context of a Docker image

```yml
script:
  - |
    docker run -i --volume $PWD:/root/mnt/home --workdir /root/mnt/home \
      --env SCENARIO \
      --env TEST \
      --env TEARDOWN \
      ...
      l2fprod/bxshell tests/runner.sh
```

The Docker image contains IBM Cloud CLI and plugins together with many useful tools (`jq` among others!).

`tests/runner.sh` performs common tasks like logging in IBM Cloud, targeting the resource group and the region. Then it runs the test and the optional teardown script.

## Adding a new test

Tests are stored under `tests`.

Let's say you worked on a new example called `vpc-example`. You would have created a folder `vpc-example` under the project root with your files there (scripts, terraform files, etc.).

To add tests for this example:
1. If it does not exist, create a new folder under `tests` with the same name (`tests/vpc-example`).
1. Write your test script, you can pick any name (`tests/vpc-example/create.sh` as example).
1. Make sure your test script is executable but you commit it.
1. Potentially create a teardown script to clean up resources.
1. [Run your test locally](#runlocal) to confirm it works.
1. Edit `.travis.yml` and add the entries to run your job:
   ```sh
    - TARGET_GENERATION=1 SCENARIO=vpc-example TEST=tests/vpc-example/create.sh TEARDOWN=tests/vpc-example/teardown.sh
    - TARGET_GENERATION=1 SCENARIO=cleanup-vpc-example TEST=tests/teardown.sh
   ```

## <a name="runlocal"></a>Running a test on your local computer as Travis will do it

1. Open `.travis.yml` for reference
1. Open a shell.
1. Set the environment variables:
   1. `API_KEY` to a IBM Cloud platform API key.
   1. `IAAS_CLASSIC_USERNAME` and `IAAS_CLASSIC_API_KEY` to IBM Cloud classic infrastructure credentials.
1. Set the environment variable `TRAVIS_JOB_ID` to a unique value like your initials -- this will be used as resource prefix in most tests.
1. Set the environment variable `KEYS` to a comma separated list of VPC SSH key names you want to inject in the VSI. If you don't specify the variable, it will be initialized to all existing keys. Most tests will inject these keys in the VSIs they create -- useful to debug a failing test until the resources have been deleted.
1. Set the environment variables defined in the `env/global` section (`TEST_VPC_NAME`, `RESOURCE_GROUP`, `REGION`).
1. Identify the test you want to run.
1. Set the environment variables defined for this test (`SCENARIO`, `TEST`, `TEARDOWN`).
1. Set the environment variable `TERRAFORM_VERSION` to latest to use Terraform version 0.12.x.If not v0.11.14 will be used.
1. Copy the `docker run...` command from `.travis.yml` and run it.
1. Wait for your test to run.

## teardown - the resource group cleaner

When tests run on Travis, [tests/teardown.sh](tests/teardown.sh) is executed by actual tests. The script will remove all VPCs under the RESOURCE_GROUP used for the tests, together with all service instances. It is pretty harsh but needed to ensure tests always run in a clean environment. BEWARE IF YOU CALL THIS WITH YOUR OWN RESOURCE GROUP.