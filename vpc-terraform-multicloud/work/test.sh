#!/bin/bash

set -eo pipefail
set -x
source local.env
for part in part*; do
  date
  (cd $part; terraform init; terraform apply -auto-approve; terraform destroy -auto-approve)
done
