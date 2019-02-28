#!/bin/bash
set -ex
basename="vpc-pubpriv"
./vpc-cleanup.sh pfq1$basename
./vpc-cleanup.sh pfq2$basename
