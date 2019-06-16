#!/bin/bash
TF=../tf
printf 'all:
  children:
    public:
      hosts:
        %s
    private:
      hosts:
        %s
' $(cd $TF; terraform output FRONT_NIC_IP), $(cd $TF; terraform output BACK_NIC_IP)