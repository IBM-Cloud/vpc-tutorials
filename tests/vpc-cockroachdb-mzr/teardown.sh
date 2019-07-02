#!/bin/bash
this_dir=$(dirname "$0")

$this_dir/../delete_ssh_key.sh
./delete.sh --template=./vpc-cockroachdb-mzr/vpc-cockroachdb-mzr.test.json --config=./vpc-cockroachdb-mzr/test.json

