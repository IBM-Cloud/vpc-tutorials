# IBM Cloud solution tutorials: Virtual Private Cloud

The scripts in this repo use the IBM Cloud CLI to set up scenarios for [VPC tutorials](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-tutorials#Network) and to clean up VPC resources.

+ [Securely access remote instances with a bastion host](vpc-secure-management-bastion-server)
+ [Private and public subnets in a Virtual Private Cloud](vpc-public-app-private-backend)
+ [Deploy isolated workloads across multiple locations and zones](vpc-multi-region)
+ [Use a VPC/VPN gateway for secure and private on-premises access to cloud resources](vpc-site2site-vpn)

Additional scenarios 

+ [Deploy CockroachDB in a Multi-Zoned Virtual Private Cloud with Encrypted Block Storage](vpc-cockroachdb-mzr)
+ [Migrate a Classic infrastructure instance to a VPC infrastructure instance](vpc-migrate-from-classic)

## Troubleshooting

The tutorials require that the CLI environment is set to **gen 1**. See the [VPC CLI documentation for details](https://cloud.ibm.com/docs/cli/reference/ibmcloud?topic=vpc-infrastructure-cli-plugin-vpc-reference#-ibmcloud-is-target-). Execute the following to set up your account:

`ibmcloud is target --gen 1`