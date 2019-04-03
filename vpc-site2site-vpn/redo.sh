#!/bin/bash
SSH_TMP_INSECURE_CONFIG=/tmp/insecure_config_file
cat > $SSH_TMP_INSECURE_CONFIG <<EOF
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel=quiet
EOF

source config.sh
(
  set -x
  . ../scripts/vpc-cleanup.sh $BASENAME -f
  . vpc-site2site-vpn-baseline-create.sh 
  . vpc-vpn-create.sh
  . network_config.sh
  scp -F $SSH_TMP_INSECURE_CONFIG network_config.sh strongswan.bash root@$ONPREM_IP:
  ssh -F $SSH_TMP_INSECURE_CONFIG root@$ONPREM_IP ./strongswan.bash
) 2>&1 | tee /tmp/tut$(date +%y:%m:%d:%H:%M)
