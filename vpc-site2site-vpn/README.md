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
1. Copy the config sample file and edit it to match your environment. The script is self documenting.  Most of the values will need to be configured.
   ```
   cp config.sh.sample config.sh
   ```
1. Create the VPC resources
   ```
   ./vpc-site2site-vpn-baseline-create.sh
   ```
   Two optional variables can be passed in. **REUSE_VPC** can be set to a VPC name to create the resources in an existing VPC environment. **CONFIG_FILE** can be set to the name of a configuration file to be used instead of the default **config.sh**.
   ```
   REUSE_VPC=vpc-name CONFIG_FILE=configuration-filename ./vpc-site2site-vpn-baseline-create.sh
   ```

Refer to [the associated solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-site2site-vpn#create-vpc) for further instructions related to the VPN gateway configuration.

### Remove the resources

Remove the VPC resources, the basename that was used to create the resources (see **config.sh**) needs to be passed in.
   ```
   BASENAME=basename ./vpc-site2site-vpn-baseline-remove.sh
   ```
If the basename does not match the name of the VPC, use REUSE_VPC to pass in the VPC name:
   ```
   BASENAME=basename REUSE_VPC=vpc-name ./vpc-site2site-vpn-baseline-remove.sh
   ```
