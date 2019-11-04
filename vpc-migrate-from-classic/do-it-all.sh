#!/bin/bash
set -e

source local.env
#bash -x ./000-prereqs.sh
#bash -x ./010-prepare-cos.sh
#bash -x ./020-create-classic-vm.sh
#bash -x ./030-capture-classic-to-cos.sh
bash -x ./040-import-image-to-vpc.sh
bash -x ./050-provision-vpc-vsi.sh
