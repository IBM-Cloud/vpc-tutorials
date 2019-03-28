# Use a VPC/VPN gateway for secure and private on-premises access to cloud resources

The scripts in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-site2site-vpn#vpc-site2site-vpn).

| File | Description |
| ---- | ----------- |
| [vpc-site2site-vpn-baseline-create.sh](vpc-site2site-vpn-baseline-create.sh) | Creates the VPC resources except the VPN. |
| [vpc-site2site-vpn-baseline-remove.sh](vpc-site2site-vpn-baseline-remove.sh) | Removes the VPC resources created by the previous script. |
| [vpc-vpc-create.sh](vpc-vpc-create.sh) | Creates a VPN Gateway between the on-premises and the cloud environments. |

## Instructions

1. Copy the config sample file and edit it to match your environment. The script is self documenting.  Most of the values will need to be configured.
   ```
   cp config.sh.sample config.sh
   ```
1. Create the VPC resources
   ```
   ./vpc-site2site-vpn-baseline-create.sh
   ```

Refer to [the associated solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-site2site-vpn#create-vpc) for further instructions related to the VPN gateway configuration.