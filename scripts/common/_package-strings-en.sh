#!/bin/bash

jq_missing_msg1="This script requires jq, but it's not installed."
jq_missing_msg2="Download the latest version for your operating system here: https://stedolan.github.io/jq/."

usage_msg1="Please supply all required parameters --config=<filename>.json --template=<filename>.json."
usage_msg1_delete="Please supply all required parameters --config=<filename>.json --template=<filename>.json.."

package_info_missing_msg1="This script cannot run without a valid package-info.json."
package_info_missing_scriptname_msg1="The package-info.json is missing a script name."
package_info_missing_version_msg1="The package-info.json is missing a script version."