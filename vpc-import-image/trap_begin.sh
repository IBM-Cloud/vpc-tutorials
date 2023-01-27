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

# include common functions
source $(dirname "$0")/../scripts/common.sh

# insure the required variables are in the environment
export_fail=false
exports=$(grep '^export' template.local.env | sed -e 's/.* \([^=]*\)=.*/\1/')
for var in $exports; do 
  if [ x$(eval echo '$'$var) = x ]; then
    echo $var - environment variable not set
    export_fail=true
  fi
done
if [ $export_fail = true ]; then
  exit
fi

# include configuration variables shared by image create and image cleanup
source $(dirname "$0")/$IMAGE_VARIABLE_FILE