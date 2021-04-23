# initialize the boot volume
set -e
systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service
echo wait for apt to become unlocked
apt-get update -y
while fuser /var/lib/dpkg/lock > /dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
  sleep 1
  echo -n .
done
apt-get install -y nginx
echo wait for nginx to come up
while ! curl localhost > /dev/null 2>&1; do
  sleep 2
  echo -n .
done
echo 1 > /var/www/html/version
while [ "$(curl -s localhost/version)" != 1 ]; do
  echo -n .
  sleep 1
done
sync
