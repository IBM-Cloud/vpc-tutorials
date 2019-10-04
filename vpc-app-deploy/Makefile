all: cli_all tf_all a_all

TF=tf
INTERNET_EXPECTING=INTERNET
NO_INTERNET_EXPECTING=ISOLATED
UPLOAD_EXPECTING=hi
PREFIX=cli
IMAGE?=ubuntu-18.04-amd64
BASH=bash -x
BASH=bash

# sanity check, did you set the environment variales?
check_TF_VARs:
	@if [[ "x$$TF_VAR_ssh_key_name" = x ]]; then \
		echo must export TF_VAR_ssh_key_name; \
		exit 1; \
	fi
	@if [[ "x$$TF_VAR_ibmcloud_api_key" = x ]]; then \
		echo must export TF_VAR_ibmcloud_api_key; \
		exit 1; \
	fi
	@if [[ "x$$TF_VAR_resource_group_name" = x ]]; then \
		echo must export TF_VAR_resource_group_name; \
		exit 1; \
	fi
cli_all: cli_apply_test cli_destroy
cli_apply_test: cli_apply cli_upload_public cli_upload_private cli_test_public cli_test_private
# resources.sh is the output of the shell script to create all of the resources
cli_apply: check_TF_VARs
	$(BASH) ../vpc-public-app-private-backend/vpc-pubpriv-create-with-bastion.sh us-south-1 $(TF_VAR_ssh_key_name) $(PREFIX) $(TF_VAR_resource_group_name) resources.sh @shared/install.sh @shared/install.sh
cli_upload_public: resources.sh
	source resources.sh ; scp -F ../scripts/ssh.notstrict.config -o ProxyJump=root@$$BASTION_IP_ADDRESS shared/uploaded.sh root@$$FRONT_NIC_IP:/uploaded.sh
	source resources.sh ; ssh -F ../scripts/ssh.notstrict.config -o ProxyJump=root@$$BASTION_IP_ADDRESS root@$$FRONT_NIC_IP sh /uploaded.sh
cli_test_public:
	source resources.sh ; bash test_provision.bash $$FRONT_IP_ADDRESS $(INTERNET_EXPECTING) $(UPLOAD_EXPECTING)
cli_upload_private: resources.sh
	source resources.sh ; scp -F ../scripts/ssh.notstrict.config -o ProxyJump=root@$$BASTION_IP_ADDRESS shared/uploaded.sh root@$$BACK_NIC_IP:/uploaded.sh
	source resources.sh ; ssh -F ../scripts/ssh.notstrict.config -o ProxyJump=root@$$BASTION_IP_ADDRESS root@$$BACK_NIC_IP sh /uploaded.sh
# scripts attach a public gateway so internet was available during  cloud-init initialization
cli_test_private:
	source resources.sh ; bash test_provision.bash $$BACK_NIC_IP $(INTERNET_EXPECTING) $(UPLOAD_EXPECTING) "ssh -F ../scripts/ssh.notstrict.config root@$$FRONT_NIC_IP -o ProxyJump=root@$$BASTION_IP_ADDRESS"
cli_destroy:
	rm -f resources.sh
	../scripts/vpc-cleanup.sh $(PREFIX)vpc-pubpriv -f

# Terraform
tf_all: tf_apply_test tf_destroy
tf_apply_test: tf_apply tf_test_public tf_test_private
tf_apply: check_TF_VARs
	cd $(TF); terraform init
	cd $(TF); terraform apply -auto-approve
tf_test_public:
	bash test_provision.bash $$(cd $(TF); terraform output FRONT_IP_ADDRESS) $(INTERNET_EXPECTING) $(UPLOAD_EXPECTING)
tf_test_private:
	bash test_provision.bash $$(cd $(TF); terraform output BACK_NIC_IP) $(NO_INTERNET_EXPECTING) $(UPLOAD_EXPECTING) "ssh -F ../scripts/ssh.notstrict.config root@$$(cd $(TF); terraform output FRONT_NIC_IP) -o ProxyJump=root@$$(cd $(TF); terraform output BASTION_IP_ADDRESS)"
tf_destroy:
	cd $(TF); terraform destroy -auto-approve


# Ansible, testing is shared using the terraform output within the ansible/tf directory
a_all: a_apply_test a_destroy
a_apply_test: a_apply a_test_public a_test_private
a_apply: check_TF_VARs
	cd ansible; $(MAKE) apply
a_test_public:
	$(MAKE) TF=ansible/tf tf_test_public
a_test_private:
	$(MAKE) TF=ansible/tf tf_test_private
a_destroy:
	cd ansible; $(MAKE) destroy
