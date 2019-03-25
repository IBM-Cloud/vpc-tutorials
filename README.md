# IBM Cloud solution tutorials: Virtual Private Cloud
The scripts in this repo use the IBM Cloud CLI to set up scenarios for VPC tutorials and to clean up VPC resources.

 + 
 + [Private and public subnets in a Virtual Private Cloud](public-app-private-backend)
 + [Use a VPC/VPN gateway for secure and private on-premises access to cloud resources](vpc-site2site-vpn)
 + Securely access remote instances with a bastion host
 + [Deploy isolated workloads across multiple locations and zones](vpc-multiregion)

## Set up a secure environment using a bastion host

Follow the IBM Cloud solution tutorial [Securely access remote instances with a bastion host](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-secure-management-bastion-server) to set up a server to manage your VPC resources.

The script [bastion-create.sh](scripts/bastion-create.sh) can be used to automatically create
* a bastion **subnet**,
* a **bastion** and a **maintenance** security group and related rules,
* a virtual server instance with the bastion ("bastion VSI") and
* a floating IP address attached to the bastion VSI.
Use the script [vpc-maintenance.sh](scripts/vpc-maintenance.sh) to attach or detach the maintenance security group to a VSI.

To add a bastion environment to your VPC environment, set few environment variables and include the script [bastion-create.sh](scripts/bastion-create.sh). Check the scripts [vpc-pubpriv-create-with-bastion.sh](vpc-public-app-private-backend/vpc-pubpriv-create-with-bastion.sh) and [vpc-site2site-vpn-baseline-create.sh](vpcsite2site-vpn/vpc-site2site-vpn-baseline-create.sh) as working examples on how to include the bastion creation.