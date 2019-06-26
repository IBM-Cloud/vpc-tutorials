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
' $(cd $TF; terraform output FRONT_NIC_IP) $(cd $TF; terraform output BACK_NIC_IP)
