#!/bin/bash
set -e

source local.env
bash ./000-prereqs.sh
bash ./010-prepare-cos.sh
bash ./020-create-classic-vm.sh
bash ./030-capture-classic-to-cos.sh
bash ./040-import-image-to-vpc.sh
bash ./050-provision-vpc-vsi.sh
bash ./060-cleanup.sh
