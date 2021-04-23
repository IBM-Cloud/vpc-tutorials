#!/bin/bash
set -e
set -o pipefail

source $(dirname "$0")/local.env

./000-prereqs.sh
./010-prepare-cos.sh
for IMAGE_VARIABLE_FILE in image_variables_debian.sh image_variables_centos7.sh image_variables_ubuntu.sh; do
  export IMAGE_VARIABLE_FILE
  env | grep IMAGE_VARIABLE_FILE
  bash -x ./020-image-create.sh
  bash -x ./030-provision-vpc-vsi.sh
  bash -x ./040-destroy-vpc-vsi.sh
  bash -x ./050-image-cleanup.sh
done
./060-cleanup-cos.sh
