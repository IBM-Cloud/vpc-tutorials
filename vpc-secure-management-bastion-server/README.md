# Securely access remote instances with a bastion host

Follow the IBM Cloud solution tutorial [Securely access remote instances with a bastion host](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-secure-management-bastion-server) to set up a server to manage your VPC resources.

The script [bastion-create.sh](scripts/bastion-create.sh) can be used to automatically create
* a bastion **subnet**,
* a **bastion** and a **maintenance** security group and related rules,
* a virtual server instance with the bastion ("bastion VSI") and
* a floating IP address attached to the bastion VSI.

The resource names are configured by the calling script and they follow this naming scheme:

| Resource type| Name(s) | Comments |
|--------------|------|----------|
| Subnet | BASENAME-BASTIONNAME-subnet|  |
| Security Group | BASENAME-BASTIONNAME-sg | |
| Security Group | BASENAME-maintenance-sg | |
| Virtual Server Instance (VSI) | BASENAME-BASTIONNAME-vsi | |
| Floating IP | BASENAME-BASTIONNAME-ip | |
The default **BASTIONNAME** is **bastion**.

Use the script [vpc-maintenance.sh](scripts/vpc-maintenance.sh) to attach or detach the maintenance security group to a VSI.

To add a bastion environment to your VPC environment, set few environment variables and include the script [bastion-create.sh](scripts/bastion-create.sh). Check the scripts [vpc-pubpriv-create-with-bastion.sh](vpc-public-app-private-backend/vpc-pubpriv-create-with-bastion.sh) and [vpc-site2site-vpn-baseline-create.sh](vpc-site2site-vpn/vpc-site2site-vpn-baseline-create.sh) as working examples on how to include the bastion creation.
