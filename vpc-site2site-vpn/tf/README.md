# Use a VPC/VPN gateway for secure and private on-premises access to cloud resources

The scripts in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-site2site-vpn#vpc-site2site-vpn).



## Resources

Refer to [the associated solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-site2site-vpn#create-vpc) for instructions

The following **named** VPC resources are created by the script above:

| Resource type| Name(s) | Comments |
|--------------|------|----------|
| Virtual Private Cloud (VPC) | BASENAME | |
| Subnet | BASENAME-bastion-subnet|  |
| Subnet | BASENAME-cloud-subnet| |
| Public Gateways | BASENAME-REGION-2-pubgw | oattached to BASENAME-cloud-subnet |
| Security Group | BASENAME-bastion-sg | |
| Security Group | BASENAME-maintenance-sg | |
| Security Group | BASENAME-cloud-sg | |
| Virtual Server Instance (VSI) | BASENAME-bastion-vsi | |
| Virtual Server Instance (VSI) | BASENAME-cloud-vsi | |
| Floating IP | BASENAME-bastion-ip | |

In addition, a classic VSI BASENAME-onprem-vsi is created.

### Terraform resource creation
The terraform configuration is in the `tf` directory. The implementation depends on the bastion module. The BASENAME is derived from the `prefix` in the variables.tf file see main.tf:
```
locals { BASENAME = "${var.prefix}-vpc" }
```

To create the resources:

```
cp export.template export
vi export; # make the changes suggested
source export
cd tf
terraform init
terraform plan
terraform apply
```

Clean up:
```
terraform destroy
```
