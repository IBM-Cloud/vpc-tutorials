#!/bin/bash
set -e
set -o pipefail

# generate the config file
echo '{
  "resources_prefix": "at'$JOB_ID'",
  "region": "'$REGION'",
  "resource_group": "'$RESOURCE_GROUP'",
  "x_use_resources_prefix": "vpc",
  "ssh_keys": [' > ./vpc-cockroachdb-mzr/test.json

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
