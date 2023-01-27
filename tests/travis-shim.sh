#!/bin/bash
set -e

if ! yq_output=$(yq --version) || ! grep mikefara <<< "$yq_output" > /dev/null; then
  echo "This program uses yq (https://github.com/mikefarah/yq/releases/tag/v4.30.u) to read the .travis.yml file"
  echo "Edit the contents of this script to work around"
  exit 1
fi

if [ -z "$API_KEY" ]; then
  echo export API_KEY=yourapikey
  echo And the rest, see template.local.env
  exit 1
fi

export TRAVIS=true

this_dir=$(dirname "$0")

# from .travis.yml, you can work around the lack of yq by copy/paste from .travis.yml
docker_script=$(yq  '.script | .[0]' $this_dir/../.travis.yml)
jobs=$(yq -r '.env.jobs | .[]' $this_dir/../.travis.yml)

# Work around missing yq or to run a specific job (eg test), newline separated jobs variable:
#docker_script='
#docker run -i --volume $PWD:/root/mnt/home --workdir /root/mnt/home \
#  --env SCENARIO \
#  --env TEST \
#  ...
#'
jobs="
  SCENARIO=vpc-lamp TEST=tests/vpc-lamp/create-with-terraform.sh
  SCENARIO=cleanup-with-terraform-vpc-lamp TEST=tests/teardown.sh    
  SCENARIO=vpc-instance-storage TEST=tests/vpc-instance-storage/create-with-terraform.sh
  SCENARIO=cleanup-with-terraform-vpc-instance-storage TEST=tests/teardown.sh  
  SCENARIO=vpc-cockroachdb-mzr TEST=tests/vpc-cockroachdb-mzr/create-with-terraform.sh
  SCENARIO=cleanup-with-terraform-vpc-cockroachdb-mzr TEST=tests/teardown.sh
"

# $1 is a newline separated list of jobs
job_array_fill(){
  local IFS=$'\n'
  for j in $1; do
    job_array+=("$j")
  done
}

# job_array will be 'SCENARIO=s1 TEST=t1','SCENARIO=s2 TEST=t2', ...
declare -a job_array
job_array_fill "$jobs"

for job in "${job_array[@]}"; do 
  if [ -z "$job" ]; then continue; fi
  eval $job
  echo SCENARIO $SCENARIO TEST $TEST 
  export SCENARIO
  export TEST
  eval "$docker_script"
done