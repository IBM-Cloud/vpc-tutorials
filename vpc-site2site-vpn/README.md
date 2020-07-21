# Use a VPC/VPN gateway for secure and private on-premises access to cloud resources

The scripts in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-site2site-vpn#vpc-site2site-vpn).

| File | Description |
| ---- | ----------- |
| [vpc-site2site-vpn-baseline-create.sh](vpc-site2site-vpn-baseline-create.sh) | Creates the VPC resources except the VPN. |
| [vpc-site2site-vpn-baseline-remove.sh](vpc-site2site-vpn-baseline-remove.sh) | Removes the VPC resources created by the previous script, including VPN gateway resources. |
| [onprem-vsi-create.sh](onprem-vsi-create.sh) | Creates a classic VSI to simulate the on-premises environments. |
| [onprem-vsi-remove.sh](onprem-vsi-remove.sh) | Remove the classic VSI. |
| [listClassicVSIs.sh](listClassicVSIs.sh) | List the id, current status and names of classic VSIs. |
| [vpc-vpc-create.sh](vpc-vpc-create.sh) | Creates a VPN Gateway between the cloud and the on-premises environments. |
| [strongswan.bash](strongswan.bash) | Creates a VPN Gateway between the on-premises and the cloud environments. Requires the generated `network_config.sh` to be copied to the on-premises environment.  |

## Instructions

### Create the environment
Refer to [the associated solution tutorial](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-site2site-vpn#create-vpc) for instructions

The following **named** VPC resources are created by the script above:

| Resource type| Name(s) | Comments |
|--------------|------|----------|
| Virtual Private Cloud (VPC) | BASENAME | only if REUSE_VPC not present |
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
