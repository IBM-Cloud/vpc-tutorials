# Use a VPC/VPN gateway for secure and private on-premises access to cloud resources

Refer to [the associated solution tutorial](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-site2site-vpn#create-vpc) for background.

## TLDR;

```
cp template.local.env local.env
# edit local.env
source local.env
terraform init
terraform apply
terraform output output_summary; # you can redirect into a file and then open
# follow the instructions in the output_sumary

# when your are done
terraform destroy
```

## Details

The following **named** VPC resources are created by the script above:

| Resource type| Name(s) | Comments |
|--------------|------|----------|
| Virtual Private Cloud (VPC) | BASENAME | |
| Subnet | BASENAME-bastion-subnet|  |
| Subnet | BASENAME-cloud-subnet| |
| Public Gateways | BASENAME-REGION-1-pubgw, BASENAME-REGION-2-pubgw, BASENAME-REGION-3-pubgw | one gateway in each zone, one attached to BASENAME-cloud-subnet |
| Security Group | BASENAME-bastion-sg | |
| Security Group | BASENAME-maintenance-sg | |
| Security Group | BASENAME-cloud-sg | |
| Virtual Server Instance (VSI) | BASENAME-bastion-vsi | |
| Virtual Server Instance (VSI) | BASENAME-cloud-vsi | |
| Floating IP | BASENAME-bastion-ip | |

In addition, a classic VSI BASENAME-onprem-vsi is created.

### Remove the resources

Remove the VPC resources, the **BASENAME** that was used to create the resources (see **config.sh**) needs to be passed in.
   ```
   BASENAME=basename ./vpc-site2site-vpn-baseline-remove.sh
   ```
If the basename does not match the name of the VPC, use REUSE_VPC to pass in the VPC name:
   ```
   BASENAME=basename REUSE_VPC=vpc-name ./vpc-site2site-vpn-baseline-remove.sh
   ```
