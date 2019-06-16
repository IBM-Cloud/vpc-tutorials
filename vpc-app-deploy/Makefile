all: all_terraform all_ansible

TF=tf
FRONT_INDEX=INTERNET
BACK_INDEX=ISOLATED
BOOTSTRAPMIN=hi
PREFIX=cli
IMAGE=centos-7.x-amd64

all_terraform:
	$(MAKE) apply
	$(MAKE) test_public
	$(MAKE) test_private
	$(MAKE) destroy

apply:
	cd $(TF); terraform init
	cd $(TF); terraform apply -auto-approve
test_public:
	bash -x ./test_provision.bash $$(cd tf; terraform output FRONT_IP_ADDRESS) $(FRONT_INDEX) $(BOOTSTRAPMIN)
test_private:
	bash -x ./test_provision.bash $$(cd tf; terraform output BACK_NIC_IP) $(BACK_INDEX) $(BOOTSTRAPMIN) "root@$$(cd tf; terraform output FRONT_NIC_IP) -o ProxyJump=root@$$(cd tf; terraform output BASTION_IP_ADDRESS)"
destroy:
	cd $(TF); terraform destroy

#all_cli_provision:
#	bash -x ../vpc-public-app-private-backend/vpc-pubpriv-create-with-bastion.sh us-south-1 $(TF_VAR_ssh_key_name) $(PREFIX) default $(IMAGE) shared/cloud-config.yaml resources.sh
#
#all_cli:
#	source resources.sh ; scp -F shared/ssh.config -o ProxyJump=root@$$BASTION_IP_ADDRESS shared/bootstrapmin.sh root@$$FRONT_NIC_IP:/bootstrapmin.sh
#	source resources.sh ; ssh -F shared/ssh.config -o ProxyJump=root@$$BASTION_IP_ADDRESS root@$$FRONT_NIC_IP sh /bootstrapmin.sh
#	source resources.sh ; bash -x test_provision $$BASTION_IP_ADDRESS $$FRONT_NIC_IP $(FRONT_INDEX) $(BOOTSTRAPMIN)
#	source resources.sh ; bash -x test_provision $$BASTION_IP_ADDRESS $$BACK_NIC_IP $(BACK_INDEX) $(BOOTSTRAPMIN)
#	# -o ProxyJump=root@169.61.245.117
#
#clean_cli:
#	../scripts/vpc-cleanup.sh $(PREFIX)vpc-pubpriv -f
#
#all_cli_BU:
#	$(MAKE) -C cli build
#	$(MAKE) test_public PUBLIC_IP
##	$(MAKE) test_private
#	$(MAKE) -C cli delete
#
#
#
## ansible uses terraform for basic initialization to create empty instances
#INVENTORY=foo
#all_ansible: ansible_prepare
#	$(MAKE) apply
#	echo a > ansible/$(INVENTORY)
#	echo '  b:' >> ansible/$(INVENTORY)
#	echo '    '$$(cd $(TF); terraform output ip) >> ansible/$(INVENTORY)
#	cd ansible; $(MAKE) all
#	$(MAKE) test_public
#	$(MAKE) test_private
#	$(MAKE) destroy
