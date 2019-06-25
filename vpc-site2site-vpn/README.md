# Use a VPC/VPN gateway for secure and private on-premises access to cloud resources

The scripts in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-site2site-vpn#vpc-site2site-vpn).

| File | Description |
| ---- | ----------- |
| [vpc-site2site-vpn-baseline-create.sh](vpc-site2site-vpn-baseline-create.sh) | Creates the VPC resources except the VPN. |
| [vpc-site2site-vpn-baseline-remove.sh](vpc-site2site-vpn-baseline-remove.sh) | Removes the VPC resources created by the previous script, including VPN gateway resources. |
| [vpc-vpc-create.sh](vpc-vpc-create.sh) | Creates a VPN Gateway between the cloud and the on-premises environments. |
| [strongswan.bash](strongswan.bash) | Creates a VPN Gateway between the on-premises and the cloud environments. Requires the generated `network_config.sh` to be copied to the on-premises environment.  |
| [redo.sh](redo.sh) | Reset the environment by calling the remove script, then recreate the baseline and establish the on-premises to cloud VPN connections. |


## Instructions

### Create the environment
1. Copy the config sample file and edit it to match your environment. The script is self documenting.  Most of the values will need to be configured. The **BASENAME** is used as prefix to all resource names.
   ```
   cp config.sh.sample config.sh
   ```
1. Create the VPC resources
   ```
   ./vpc-site2site-vpn-baseline-create.sh
   ```
   Two optional variables can be passed in. **REUSE_VPC** can be set to a VPC name to create the resources in an existing VPC environment. Else, a new VPC with the name of the configured **BASENAME** will be created. **CONFIG_FILE** can be set to the name of a configuration file to be used instead of the default **config.sh**.
   ```
   REUSE_VPC=vpc-name CONFIG_FILE=configuration-filename ./vpc-site2site-vpn-baseline-create.sh
   ```

Refer to [the associated solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-site2site-vpn#create-vpc) for further instructions related to the VPN gateway configuration.

The following **named** resources are created by the script above:

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

### Remove the resources

Remove the VPC resources, the **BASENAME** that was used to create the resources (see **config.sh**) needs to be passed in.
   ```
   BASENAME=basename ./vpc-site2site-vpn-baseline-remove.sh
   ```
If the basename does not match the name of the VPC, use REUSE_VPC to pass in the VPC name:
   ```
   BASENAME=basename REUSE_VPC=vpc-name ./vpc-site2site-vpn-baseline-remove.sh
   ```
