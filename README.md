# IBM Cloud solution tutorials: Virtual Private Cloud

> **Important:** IBM will be accepting a limited number of customers to participate in an Early Access program to VPC starting in early April, 2019 with expanded usage being opened in the following months. If your organization would like to gain access to IBM Virtual Private Cloud, please complete [this nomination form](https://cloud.ibm.com/vpc) and an IBM representative will be in contact with you regarding next steps.

The scripts in this repo use the IBM Cloud CLI to set up scenarios for [VPC tutorials](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-tutorials#Network) and to clean up VPC resources.

+ [Securely access remote instances with a bastion host](vpc-secure-management-bastion-server)
+ [Private and public subnets in a Virtual Private Cloud](vpc-public-app-private-backend)
+ [Deploy isolated workloads across multiple locations and zones](vpc-multi-region)
+ [Use a VPC/VPN gateway for secure and private on-premises access to cloud resources](vpc-site2site-vpn)

## Behind the scenes
The script currently does a few interesting things:

- check if `jq` is installed as it is required

- validates the `ibmcloud` cli is installed and at the required minimum version as noted in the `package-info.json`.

- validates the plugins to ibmcloud cli as listed in the `package-info.json` are installed at the minimum version.

- takes its build instructions, i.e. what environment to build from a `.json` file.

- creates a resource only if it does not exist, re-uses if the resource already exist.

- adds the resource id and additional information as needed to the corresponding build `.json` file.

- creates the following: 
    - Virtual Private Cloud [VPC](./docs/vpc.md):
        - [Subnets](./docs/subnets.md)
        - [Gateways](./docs/gateways.md)
        - [Security Groups](./docs/security-groups.md)
        - Virtual Server Instances [VSIs]](./docs/virtual-servers.md)
            - data block storage with encryption (added to the appropriate VSI)
            - floating IP
        - [Load Balancers](./docs/load-balancers.md)
    - Services:
        - [Key Protect Instance and Root Key](./docs/encryption-key.md)
        - cloud object storage
    - runs a custom [user data](https://cloud.ibm.com/docs/vsi-is?topic=virtual-servers-is-user-data#user-data) shell script on a targeted vsi when it starts for the very first time to perform some hardware and software configuration.
    - runs a custom `ssh-init` shell script on a targeted VSI after it is started to perform some software configuration tasks.

- all resources as they are created will need to have a prefix added to them, this makes it easier to identify which resources are for a specific project.  You can pass a parameter to the script `--x_use_resources_prefix` and add a comma separated list of the resources you do not want the prefix added to, i.e. `--x_use_resources_prefix=vpc,services_intances` will create the VPC and service instances without adding the prefix.

## Known Issues
- Does not create ACLs