# trap_begin.sh sourced from each of the step files at the beginning of the file
set -e
set -o pipefail
success=unknown
trap check_finish EXIT
check_finish() {
  if [ $success = true ]; then
    echo '>>>' success
  else
    echo "FAILED"
  fi
}
check_exports(){
  export_file=$1
  export_fail=false
  exports=$(grep '^export' $export_file | sed -e 's/.* \([^=]*\)=.*/\1/')
  for var in $exports; do 
    if [ x"$(eval echo '$'$var)" = x ]; then
      echo $var - environment variable not set
      export_fail=true
    fi
  done
  if [ $export_fail = true ]; then
    false
  fi
}

# include common functions
source $(dirname "$0")/../scripts/common.sh

# insure the required variables are in the environment
check_exports template.local.env


# todo
# include configuration variables shared by image create and image cleanup
#source $(dirname "$0")/image_variables/$IMAGE_VARIABLE_FILE