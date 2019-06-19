all: all_terraform all_ansible

TF=tf
FRONT_INDEX=INTERNET
BACK_INDEX=ISOLATED
BOOTSTRAPMIN=hi
PREFIX=cli
IMAGE=centos-7.x-amd64

# Terraform
tf_all: tf_apply_test tf_destroy
tf_apply:
	cd $(TF); terraform init
	cd $(TF); terraform apply -auto-approve
tf_test_public:
	./test_provision.bash $$(cd $(TF); terraform output FRONT_IP_ADDRESS) $(FRONT_INDEX) $(BOOTSTRAPMIN)
tf_test_private:
	./test_provision.bash $$(cd $(TF); terraform output BACK_NIC_IP) $(BACK_INDEX) $(BOOTSTRAPMIN) "root@$$(cd $(TF); terraform output FRONT_NIC_IP) -o ProxyJump=root@$$(cd $(TF); terraform output BASTION_IP_ADDRESS)"
tf_apply_test: tf_apply tf_test_public tf_test_private
tf_destroy:
	cd $(TF); terraform destroy -auto-approve

# Ansible, testing is shared using the terraform output within the ansible/tf directory
a_all: a_apply_test a_destroy
a_apply:
	cd ansible; $(MAKE) apply
a_test_public:
	$(MAKE) TF=ansible/tf tf_test_public
a_test_private:
	$(MAKE) TF=ansible/tf tf_test_private
a_apply_test: a_apply a_test_public a_test_private
a_destroy:
	cd ansible; $(MAKE) destroy