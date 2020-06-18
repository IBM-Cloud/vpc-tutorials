#!/bin/bash

set -eo pipefail
set -x
source local.env
for generation in 1 2; do
  export TF_VAR_generation=$generation
  for part in part*; do
    date
    (cd $part; terraform init; terraform apply -auto-approve; terraform destroy -auto-approve)
  done
done
