#!/bin/bash

read_terraform_variable() {
  terraform output -raw -state $this_dir/terraform/terraform.tfstate $1
}
ssh_it() {
  local host=$1
  if ! ssh_it_out_and_err=$(ssh -o "StrictHostKeyChecking=no" root@$host 2>&1); then
    cat <<< "$ssh_it_out_and_err"
    return 1
  fi
}

_WAIT_TIME=600
wait_for_command() {
  # command="$1"
  let "begin = $(date +'%s')"
  local elapsed=0
  local first_time=true
  while (( $_WAIT_TIME > $elapsed )); do
    if eval "$1"; then
      [ $first_time = false ] && echo
      return 0
    fi
    [ $first_time = true ] && echo -n retry for $_WAIT_TIME seconds: ''
    first_time=false
    sleep 10
    let "elapsed = $(date +%s) - $begin"
    echo -n $elapsed ''
  done
  echo
  return 1
}

