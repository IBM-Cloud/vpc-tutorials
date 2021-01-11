#!/bin/bash
set -e
set -o pipefail

my_dir=$(dirname "$0")

(
  cd $my_dir/create-vpc-vsi
  terraform init
  terraform destroy --auto-approve
)
