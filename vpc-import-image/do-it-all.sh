#!/bin/bash
set -e
set -o pipefail

source $(dirname "$0")/local.env

./000-prereqs.sh
./010-prepare-cos.sh
./020-image-create.sh
./030-provision-vpc-vsi.sh
./040-destroy-vpc-vsi.sh
./050-image-cleanup.sh
./060-cleanup-cos.sh
