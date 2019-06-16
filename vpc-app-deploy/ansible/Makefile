BASTION_IP_ADDRESS=


public:
	$(MAKE) ansible TARGET=public BASTION_IP_ADDRESS=$$(cd ../tf; terraform output BASTION_IP_ADDRESS)

private:
	$(MAKE) ansible TARGET=private BASTION_IP_ADDRESS=$$(cd ../tf; terraform output BASTION_IP_ADDRESS)

ansible:
	echo ansible-playbook -l $(TARGET) --ssh-common-args '-o ProxyJump=root@$(BASTION_IP_ADDRESS)' -i inventory lamp.yaml 
	# ANSIBLE_DEBUG=1 ansible-playbook -l $(TARGET) --ssh-common-args '-o ProxyJump=root@$(BASTION_IP_ADDRESS)' -i inventory lamp.yaml 
