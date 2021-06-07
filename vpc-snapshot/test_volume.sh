# initialize the boot volume
set -e
volumes_expected=2
volumes=0
for found_mount_point in $(findmnt -n -l --type ext4 -o TARGET | grep datavolumes); do
  echo test $found_mount_point
  (
    if ! [ -r $found_mount_point/version.txt ]; then
      echo no version.txt file found expected $found_mount_point/version.txt
    fi
    source $found_mount_point/version.txt
    if [ $version != 1 ]; then
      echo bad version expected 1 got $version
      exit 1
    fi
    if [ $mount_point != $found_mount_point ] ; then
      echo bad mount_point in version.txt expected $found_mount_point got $mount_point
      exit 1
    fi
  )
  let volumes+=1
done
if [ $volumes != $volumes_expected ]; then
  echo bad number of volumes expected $volumes_expected got $volumes
  exit 1
fi
