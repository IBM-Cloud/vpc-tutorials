#!/bin/bash
set -e
set -o pipefail

# generate an SSH key for the test
ssh-keygen -t rsa -P "" -C "automated-tests@build" -f $HOME/.ssh/id_rsa
export TEST_KEY_NAME="automated-tests-${JOB_ID}"
ibmcloud is key-create $TEST_KEY_NAME @$HOME/.ssh/id_rsa.pub

# generate the config file
echo '{
  "resources_prefix": "at'$JOB_ID'",
  "region": "'$REGION'",
  "resource_group": "'$RESOURCE_GROUP'",
  "x_use_resources_prefix": "vpc",
  "ssh_keys": [
    {
      "name": "'$TEST_KEY_NAME'",
      "type": "vpc"
    },' > ./vpc-cockroachdb-mzr/test.json

keynames=$KEYS
keys=()
while [ "$keynames" ] ;do
  iter=${keynames%%,*}
  echo -n '    {
      "name": "'$iter'",
      "type": "vpc"
    }' >> ./vpc-cockroachdb-mzr/test.json
  [ "$keynames" = "$iter" ] && \
  keynames='' || \
  keynames="${keynames#*,}"
  if [ "$keynames" ]; then
    echo ',' >> ./vpc-cockroachdb-mzr/test.json
  fi
done

echo '
  ]
}' >> ./vpc-cockroachdb-mzr/test.json

cp ./vpc-cockroachdb-mzr/vpc-cockroachdb-mzr.template.json \
  ./vpc-cockroachdb-mzr/vpc-cockroachdb-mzr.test.json
sed -i 's/vpc-cockroachdb/'$TEST_VPC_NAME$'/g' ./vpc-cockroachdb-mzr/vpc-cockroachdb-mzr.test.json

# deploy the config
./build.sh --template=./vpc-cockroachdb-mzr/vpc-cockroachdb-mzr.test.json --config=./vpc-cockroachdb-mzr/test.json
