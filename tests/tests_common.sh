#!/bin/bash

# source source scripts/common.sh before using these commands
# ssh key name for job
function ssh_key_name_for_job() {
  echo automated-tests-${JOB_ID}
}

# create ssh key
function ssh_key_create() {
  test_key_name=$1
  if [ -e $HOME/.ssh/id_rsa ]; then
    echo not creating a new '~/.ssh/id_rsa' file, will re-use the existing
  else
    ssh-keygen -t rsa -P "" -C "automated-tests@build" -f $HOME/.ssh/id_rsa
  fi
  ibmcloud is key-create $test_key_name @$HOME/.ssh/id_rsa.pub
}

# remove the key created for this job
function ssh_key_delete_if_exists() {
  test_key_name=$1
  test_key_id=$(SSHKeynames2UUIDs $test_key_name)
  if [ x"$test_key_id" != x ]; then
    ibmcloud is key-delete $test_key_id --force
  fi
}
