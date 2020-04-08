#!/bin/bash

# usage: ./test_provision.sh host_ip expectingIndex expectingUpload [ssh_command]

# curl (from the bastion host if ssh_command to the bastion is provided)
# looking for the expected contets of the /index.html (expectingIndex)
# and /testupload.html (expectingUpload)

if (( ($# < 3) || ($# > 4) )); then
  echo usage $0 host_ip expectingIndex expectingUpload [ssh_command]
  exit 1
fi
host_ip=$1
expectingIndex=$2
expectingUploadtest=$3
ssh_command="$4"

testuploadfile=testupload.html
elapsed=0
total=600
let "begin = $(date +%s)"
while (( $total > $elapsed)); do
    contents=$($ssh_command curl -s http://$host_ip)
    if [ "x$contents" = x$expectingIndex ]; then
      echo success: httpd default file was correctly replaced with the following contents:
      echo $contents
      hi=$($ssh_command curl -s http://$host_ip/$testuploadfile)
      if [ "x$hi" = "x$expectingUploadtest" ]; then
        echo success: provision of file from on premises worked and was replaced with the following contents:
        echo $hi
        exit 0
      else
        echo $hi
        echo "fail: provisioning did not work, expecting $expectingUploadtest but got the stuff above intead"
        exit 2
      fi
      exit 0
    else
      echo $contents
      echo 
      echo Fail, expected $expectingIndex, but got the stuff shown above instead, will try again
    fi

    # while loop end:
    sleep 10
    let "elapsed = $(date +%s) - $begin"
    echo $elapsed seconds of $total have elapsed, try again...
done
exit 1
