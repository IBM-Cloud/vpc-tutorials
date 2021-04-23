#!/bin/bash
set -e
this_dir=$(dirname "$0")
bash -x $this_dir/snapshot.sh test
