BASTION_IP_ADDRESS=
TF=tf

apply: public private
inventory:
	cd $(TF); terraform init
	cd $(TF); terraform apply -auto-approve
	./inventory.bash > inventory
public: inventory
	$(MAKE) ansible TARGET=FRONT_NIC_IP BASTION_IP_ADDRESS=$$(cd $(TF); terraform output BASTION_IP_ADDRESS)
private: inventory
	$(MAKE) ansible TARGET=BACK_NIC_IP BASTION_IP_ADDRESS=$$(cd $(TF); terraform output BASTION_IP_ADDRESS)
ansible1:
	#echo  ssh -F ../shared/ssh.config -o ProxyJump=root@$(BASTION_IP_ADDRESS) root@$$(cd tf; terraform output $(TARGET)) uname -a
	ansible-playbook -vvvv -T 60 -l $(TARGET) -u root --ssh-common-args '-F ../shared/ssh.config -o ProxyJump=root@$(BASTION_IP_ADDRESS) -o CheckHostIP=no' -i inventory lamp.yaml 
ansible:
	echo ssh -o ProxyJump=root@$(BASTION_IP_ADDRESS) root@$$(cd tf; terraform output $(TARGET)) uname -a
	ansible-playbook -vvvv -T 60 -l $(TARGET) -u root --ssh-common-args '-o ProxyJump=root@$(BASTION_IP_ADDRESS) -o CheckHostIP=no' -i inventory lamp.yaml 
destroy:
	cd $(TF); terraform destroy -auto-approve
	rm inventory


# Optionally install ansible in a virtual env if it is not available on your computer.
# After making prereq source ./pyvirt/bin/activate in your shell to put ansible-playbook on your path
prereq:
	virtualenv pyvirt
	. ./pyvirt/bin/activate; pip install ansible
