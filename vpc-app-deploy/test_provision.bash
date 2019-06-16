#!/bin/bash

# will curl from the local host or from the bastion host if provided
# looking for the expected contets of the /index.html (expectingIndex)
# and the noindex/css/bootstrap.min.css (expectingBootgstrap)

if (( ($# < 3) || ($# > 4) )); then
  echo usage $0 host_ip expectingIndex expectingBoostrap [bastion_ip]
  exit 1
fi
host_ip=$1
expectingIndex=$2
expectingBootstrap=$3
bastion_ip=$4

bootstrapfile=noindex/css/bootstrap.min.css
elapsed=0
total=600
let "begin = $(date +%s)"
while (( 600 > $elapsed)); do
    if [ "x$bastion_ip" = x ]; then
		  contents=$(curl -s $host_ip)
    else
		  contents=$(ssh -F shared/ssh.config $bastion_ip curl -s $host_ip)
    fi
    if [ "x$contents" = x$expectingIndex ]; then
      echo success: httpd default file was correctly replaced with the following contents:
      echo $contents
      if [ "x$bastion_ip" = x ]; then
        hi=$(curl -s $host_ip/$bootstrapfile)
      else
        hi=$(ssh -F shared/ssh.config $bastion_ip curl -s $host_ip/$bootstrapfile)
      fi
      if [ "x$hi" = "x$expectingBootstrap" ]; then
        echo success: provision of file from on premises worked and was replaced with the following contents:
        echo $hi
        exit 0
      else
        echo $hi
        echo "fail: terraform provision does not work, expecting $expectingBootstrap but got the stuff above intead"
        exit 2
      fi
      exit 0
    else
      echo $contents
      echo 
      echo Fail, expected $expectingIndex, but got the stuff shown above instead, will try again
      sleep 1
    fi

    # while loop end:
    sleep 10
    let "elapsed = $(date +%s) - $begin"
    echo $elapsed of $total have elapsed, try again...
done
exit 1
