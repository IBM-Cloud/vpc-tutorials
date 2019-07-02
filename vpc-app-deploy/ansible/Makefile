BASTION_IP_ADDRESS=
TF=tf

apply: ansible_exists public private
inventory:
	cd $(TF); terraform init
	cd $(TF); terraform apply -auto-approve
	./inventory.bash > inventory
public: inventory
	$(MAKE) ansible TARGET=FRONT_NIC_IP BASTION_IP_ADDRESS=$$(cd $(TF); terraform output BASTION_IP_ADDRESS)
private: inventory
	$(MAKE) ansible TARGET=BACK_NIC_IP BASTION_IP_ADDRESS=$$(cd $(TF); terraform output BASTION_IP_ADDRESS)
ansible:
	ansible-playbook -T 40 -l $(TARGET) -u root --ssh-common-args '-F ../../scripts/ssh.notstrict.config -o ProxyJump=root@$(BASTION_IP_ADDRESS)' \
		-i inventory lamp.yaml 
destroy:
	cd $(TF); terraform destroy -auto-approve
	rm inventory

ansible_exists:
	@if ! which ansible-playbook; then \
		echo ansible-playbook must be installed and on your path.  It can be installed locally as described in the Makefile; \
		echo $(PWD)/Makefile; \
		echo see target prereq; \
		exit 1; \
	fi
# Optionally install ansible in a virtual env if it is not available on your computer.
# After making prereq source ./pyvirt/bin/activate in your shell to put ansible-playbook on your path
prereq:
	virtualenv pyvirt
	. ./pyvirt/bin/activate; pip install ansible
