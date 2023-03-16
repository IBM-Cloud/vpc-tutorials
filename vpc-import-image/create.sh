#!/bin/bash
set -e
set -o pipefail
source $(dirname "$0")/trap_begin.sh
./000-prereqs.sh
./010-prepare-cos.sh
./020-qcow-create.sh
./025-image-create.sh
./030-provision-vpc-vsi.sh
./035-pull-instance-data.sh
source $(dirname "$0")/trap_end.sh
