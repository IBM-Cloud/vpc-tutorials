# Testing for developers
Insider information for developers of the repository (not the users of the tutorials and blogs)

There is an automated test suite that runs on travis.  Check out the .travis.yml

The travis environment can be replicated on a desktop using the shell script `travis-desktopshim.sh`.  Edit the script for more information: To run all of the tests in the parent directory:

```sh
./tests/travis-shim.sh
```

First setup the environment (try an local.env file:)
```
# source for running travisrunner.sh on your desktop
export API_KEY=yourApiKey
export IAAS_CLASSIC_USERNAME=IBMid-YourClassicUser
export IAAS_CLASSIC_API_KEY=YourClassicAPIKEY
export KEYS=yourKey
export TRAVIS_JOB_ID=tjid004
export RESOURCE_GROUP=yourRG
export REGION=us-south
export DATACENTER=dal10
export TERRAFORM_VERSION=latest
```

To debug interactively in the docker container.  A bash shell will be presented after initialization:

```sh
DEBUG=1 ./tests/travis-shim.sh
```



