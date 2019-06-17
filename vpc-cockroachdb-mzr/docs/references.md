## Environment Overview
A high availability environment can typically include as little as 2 nodes in a cluster. However, in this scenario we will be using CockroachDb as our database server and we will follow the [CockroachDB recommendation for a 3 nodes cluster](https://www.cockroachlabs.com/docs/stable/recommended-production-settings.html#basic-topology-recommendations) for a multi-active availability database environment. Such environment can be deployed in any of the multi-zones regions in the IBM Cloud and the 3 nodes distributed to each of the 3 zones in the given region.

![](./docs/diagrams/Slide1.PNG)

## Components to be deployed
[VPC Components Glossary](https://cloud.ibm.com/docs/infrastructure/vpc?topic=vpc-vpc-glossary)

#### VPC
A virtual network tied to an account. It provides fine-grained control over virtual infrastructure and network traffic segmentation, along with security and the ability to scale dynamically.
[About VPC](https://cloud.ibm.com/docs/infrastructure/vpc-network?topic=vpc-network-about-networking-for-vpc)

#### Subnet
A subnet is an IP address range, bound to a single Zone, which cannot span multiple Zones or Regions. A subnet can span the entirety of a zone in an IBM Cloud VPC.
Virtual server instances (VSIs) are assigned an IP address within the subnet that you require.
[About Subnets](https://cloud.ibm.com/docs/infrastructure/vpc-network?topic=vpc-network-working-with-ip-address-ranges-address-prefixes-regions-and-subnets#ibm-cloud-vpc-and-subnets)


- The following provided configuration template [cockroachdb-template.json](./vpc-cockroachdb-mzr.template.json) will create all the resources in the [Environment Overview](#environment-overview) section and install/configure cockroachDB on the database VSI.

- Supporting scripts are also available that run on targeted virtual server instances(vsi).

    #### cloud-init scripts

    |   Name	|   Description	|
    |---	|---	|
    |   `cockroachdb.sh`	|   Creates the block storage partition, updates /etc/fstab and mounts it. Installs and configures each node in the CockroachDB cluster to run as a service (systemd) and and sets up the ntp service (typically required for database clusters to have a time service running on the nodes).	|
    |   `app-deploy.sh`	|   Installs nodejs and deploys a small app to interact with a backend database service.	|


    #### ssh-init scripts

    |   Name	|   Description	|
    |---	|---	|
    |   `cockroachdb.sh`	|   Configure cockroachdb. 	|
    |   `cockroachdb-admin.sh`	|   Initialize the cockroachdb cluster for the very first time.	|
    |   `app-configure.sh`	|   configure the app with settings obtained during the build, i.e. load balancer address.	|
  
  
#### Security Group
A security group acts as a virtual firewall that controls the **inbound and outbound** traffic for one or more servers (VSIs). A security group is a collection of rules that specify whether to allow traffic for an associated VSI
[About Security Groups](https://cloud.ibm.com/docs/infrastructure/vpc-network?topic=vpc-network-using-security-groups)

#### Public Gateway
A Public Gateway (PGW) enables **outbound-only** access for a subnet (with all the VSIs attached to the subnet) to connect to the internet. Note that subnets are private by default; however, optionally, you can create a PGW and attach a subnet to the PGW. After a subnet is attached to the PGW, all the VSIs in that subnet can connect to the internet.
[About Public Gateways](https://cloud.ibm.com/docs/infrastructure/vpc-network?topic=vpc-network-about-networking-for-vpc#use-a-public-gateway)

#### Regions and Zone
A Region is a geographic area within which a VPC is deployed. Each region contains multiple zones, which represent independent fault domains. IBM Cloud VPC spans multiple zones within its assigned region.

A Zone is an independent fault domain. A Zone is an abstraction designed to assist with improved fault tolerance(it is extremely unlikely for two zones in a region to fail simultaneously) and decreased latency(less than 2ms in latency).

#### Virtual Server(Compute) Instances (VSIs)
A compute instance running the operating system of your choice along with the database and/or application

#### Block Storage
Persistent high-performance block storage volumes for your virtual server instances (VSIs) all backed by SSD. Block Storage for VPC provides primary boot volumes and secondary data volumes. Boot volumes are automatically created and attached during VSI provisioning. Data volumes can be created and attached during VSI provisioning as well. To protect your data, you can use your own encryption key or choose IBM-managed encryption for each the boot and data volume(s).
[About Block Storage for VPC](https://cloud.ibm.com/docs/infrastructure/block-storage-is?topic=block-storage-is-block-storage-about&topicid=block-storage-is-block-storage-about)

## Key protect instance
The VSIs that will be created for CockroachDB will each have a data block storage added. This block storage is by default encrypted with a cloud provided key, however customers can create or specify their own keys if they leverage the Key Protect service.

The script will generate a Key Protect instance and create a key that will be used to encrypt the block storage. 

## Certificate Manager instance
The VSIs that will be created for CockroachDB will each a certificate created that is used to securely communicate with each node, in addition a certificate is created for the root user as well as an application user called "maxroach". These certificates are stored securely in Certificate Manager where you get a central view of the certificates that you are using. You can manage your certificates in the following ways:

- Get notified before your certificates expire to ensure that you renew them on time
- Use notifications to trigger automated certificate renewal
- View the types of certificates across your deployments and ensure that they meet organization policies
- Find certificates that need replacing when new compliance or security requirements are issued
- Set controls on who can access and manage your certificates
- Order new public certificates

The script will generate a Certificate Manager instance and import all the keys used for communicating with the cockroach nodes. 