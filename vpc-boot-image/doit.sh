set -e
this_dir=$(dirname "$0")
while :; do
  $this_dir/020-snapshot-create.sh
  $this_dir/030-snapshot-test.sh
done
