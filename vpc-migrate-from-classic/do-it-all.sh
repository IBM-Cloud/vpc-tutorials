#!/bin/bash
set -e

./000-prereqs.sh
./010-prepare-cos.sh
./020-create-classic-vm.sh
./030-capture-classic-to-cos.sh
./040-import-image-to-vpc.sh
./050-provision-vpc-vsi.sh
