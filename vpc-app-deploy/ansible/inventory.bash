#!/bin/bash
TF=tf
printf 'all:
  children:
    FRONT_NIC_IP:
      hosts:
        %s
    BACK_NIC_IP:
      hosts:
        %s
' $(cd $TF; terraform output -raw FRONT_NIC_IP) $(cd $TF; terraform output -raw BACK_NIC_IP)
