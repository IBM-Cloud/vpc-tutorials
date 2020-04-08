#!/bin/bash

# include common functions
my_dir=$(dirname "$0")
. $my_dir/../scripts/common.sh

show_help() {
  echo "$1"
  exit 1
}
install_software() {
  [ x$PIPELINE_ID = x ] && return; # not running in a pipline 
  # terraform
  TERRAFORM_VERSION=0.11.14
  wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin 
  terraform -version

  # ibm terraform provider plugin
  mkdir $HOME/.terraform.d/plugins
  wget https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v0.18.0/linux_amd64.zip  
  unzip linux_amd64.zip
  mv terraform-provider-ibm* $HOME/.terraform.d/plugins/

  # ibmcloud cli
  ibmcloud --version
  ibmcloud login --apikey $IBMCLOUD_API_KEY -r $REGION
  ibmcloud plugin install vpc-infrastructure -f
  ibmcloud plugin install cloud-object-storage -f
  ibmcloud is target --gen 1
  ibmcloud plugin update -all
}
# 20 character name starts with letter and then letters numbers and -
sanitize_prefix() {
  s=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  # if the first char is not a letter make it an a
  first=$(echo -n ${s:0:1} | tr -C -s a-z a)
  # lower case or numbers only all others replaced with -
  rest=$(echo -n ${s:1} | tr -C -s '\055a-z0-9' '\055')
  # remove multiple occurrances of -
  rest=$(echo -n $rest | tr -s '\055\055' '\055')
  echo $first${rest:0:19}
}

# region from a dropdown looks like this: ibm:yp:us-south
region_part() {
  local IFS=':'
  parts=( $REGION )
  echo ${parts[2]}
}

# make sure all of the expected environment vars are set
environ_verify_setup() {
  # Verify environment variables are set
  not_prefix="REGION IBMCLOUD_API_KEY IAAS_CLASSIC_USERNAME IAAS_CLASSIC_API_KEY RESOURCE_GROUP_NAME
    COS_SERVICE_NAME COS_SERVICE_PLAN COS_REGION COS_BUCKET_NAME DATACENTER VPC_IMAGE_NAME"
  for var in PREFIX $not_prefix; do
    eval '[ -z ${'$var'+x} ]' && show_help "$var not set.  A pipeline property property must define this variable"
  done
  PREFIX=$(sanitize_prefix "$PREFIX")
  REGION=$(region_part)
  # Eval each of the variables to expand PREFIX
  for var in $not_prefix; do
    eval "tmp=\$$var"
    eval "$var=$tmp"
    eval echo \$$var
  done
}

# absolute file name
get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

# generate an ssh public private key, public ends in .pub
ssh_keygen() {
  if ! [ -f $ssh_keygen_files ]; then
    ssh_public_key_file="$abs_ssh_keygen_f.pub"
    ssh-keygen -t rsa -f $ssh_keygen_files -N ''
  fi
  abs_ssh_keygen_f=$(get_abs_filename $ssh_keygen_files)
  export SSH_PUBLIC_KEY="$abs_ssh_keygen_f.pub"
  export SSH_PRIVATE_KEY="$abs_ssh_keygen_f"
}
save_terraform_state() {
# Adding support for the save/restoree of terraform state would allow stages to be restarted after a failure
# if $COS_BUCKET_NAME bucket exists then save terraform state
  return
}
restore_terraform_state() {
# if terraform state file exists in $COS_BUCKET_NAME then restore terraform state
  return
}
final_clean_up() {
  # remove the COS instance
  COS_INSTANCE_ID=$(get_instance_id $COS_SERVICE_NAME)
  if ! ibmcloud resource service-instance-delete $COS_INSTANCE_ID --force --recursive; then
    echo FAILED: ibmcloud resource service-instance-delete $COS_INSTANCE_ID --force --recursive
  else
    echo ibmcloud resource service-instance-delete $COS_INSTANCE_ID
  fi
}

[ -f build.properties ] && source build.properties
environ_verify_setup
install_software

my_dir=$(dirname "$0")
ssh_keygen_files=ssh_keygen_files
ssh_keygen

# configure the scripts for pipeline mode instead of blog mode
export COS_BUCKET_SERVICE_KEEP=true
export VPC_IMAGE_KEEP=true
export VPC_SSH_KEY_CREATE=true
export VPC_SSH_KEY_NAME=$PREFIX-ssh-key

restore_terraform_state
for script in $*; do
  if [ $script = final_clean_up ]; then
    final_clean_up
  else
    bash $my_dir/$script
  fi
done
exit_status=$?
save_terraform_state
[ x$DATE = x ] && DATE=$(date "+%Y-%m-%d-%H-%M-%S");# stage 1 date
[ x$ARCHIVE_DIR = x ] && ARCHIVE_DIR=.;# running on desktop
mkdir -p $ARCHIVE_DIR
echo "DATE=${DATE}" >> $ARCHIVE_DIR/build.properties
exit $exit_status
