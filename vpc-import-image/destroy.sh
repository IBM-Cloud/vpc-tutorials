#!/bin/bash
set -e
set -o pipefail
source $(dirname "$0")/trap_begin.sh
./040-destroy-vpc-vsi.sh
./050-image-cleanup.sh
./060-cleanup-cos.sh
source $(dirname "$0")/trap_end.sh
