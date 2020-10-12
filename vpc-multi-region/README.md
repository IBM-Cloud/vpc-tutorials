# Deploy isolated workloads across multiple locations and zones

The scripts in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-multi-region#vpc-multi-region).

| File | Description |
| ---- | ----------- |
| [vpc-multi-region-single-create.sh](vpc-multi-region-single-create.sh) | Creates VPC resources in a single region. |
| [vpc-multi-region-create.sh](vpc-multi-region-create.sh) | Creates VPC resources in multiple regions. |
| [vpc-multi-region-cleanup.sh](vpc-multi-region-cleanup.sh) | Removes all created resources. |
| [cis/cis-glb-create.sh](cis/cis-glb-create.sh) | Configures a global load balancer. |

## Instructions

1. In a browser visit [IAM authorizations](https://cloud.ibm.com/iam/authorizations) and add an authorization from the source: **VPC Infrastructure**, **Load Balancer for VPC** to the Target **Certificate Manager**
1. Target the VPC generation:

   ```
   ibmcloud is target --gen 2
   ```

1. Open the terminal and add your SSH key

    ```
    ssh-add -K ~./ssh/<YOUR_PRIVATE_KEY>
    ```

1. Navigate to `vpc-multi-region` folder in the repo and create a `.env` file from the template

   ```
    cd vpc-multi-region
    cp template.env .env
   ```

1. Provide the required details in the `.env` file and save.

1. Execute the shell script and follow the steps of execution to setup VPCs in multiple regions in ONE-GO

    ```
    ./vpc-multi-region-create.sh
    ```
1. For creating VPC resources in a single region, run this script
    ```
    ./vpc-multi-region-single-create <REGION_NAME>
    ```
    The following **named** resources are created by the script above:
    
    | Resource type| Name(s) | Comments |
    |--------------|------|----------|
    | Virtual Private Cloud (VPC) | BASENAME-REGION | |
    | Subnet | BASENAME-bastion-REGION-ZONE1|  |
    | Subnet | BASENAME-REGION-ZONE1-subnet| |
    | Subnet | BASENAME-REGION-ZONE2-subnet| |
    | Security Group | BASENAME-bastion-REGION-ZONE1-sg | |
    | Security Group | BASENAME-maintenance-sg | |
    | Security Group | BASENAME-sg | |
    | Virtual Server Instance (VSI) | BASENAME-bastion-REGION-ZONE1-vsi | |
    | Virtual Server Instance (VSI) | BASENAME-REGION-zone1-vsi | |
    | Virtual Server Instance (VSI) | BASENAME-REGION-zone2-vsi | |
    | Floating IP | BASENAME-bastion-ip | |
    | Floating IP | BASENAME-REGION-zone1-ip | |
    | Floating IP | BASENAME-REGION-zone2-ip | |
    | Load Balancer | BASENAME-REGION-lb | |
    | Load Balancer back-end pool | BASENAME-REGION-lb-pool | Instances are attached as `pool members` to the pool with HTTP and HTTPS **front-end listeners**|


1. The Global Load Balancer will be connected to the VPC Load balancers when using the vpc-multi-region-create.sh.  If executing manually run the below script to create a Global Load Balancer(GLB)
    ```
    cd cis
    ./cis-glb-create.sh
    ```
### Cleanup

1. Run the below script to delete CIS GLB resources and VPC resources in ONE-GO.
    ```
    ./vpc-multi-region-cleanup.sh <VPC_NAME> <LOAD_BALANCER_NAME>
    ```
1. To delete VPC resources,
    ```
    cd ../scripts && ./vpc-cleanup.sh <VPC_NAME>
    ```
1. To delete CIS global load balancer resources,
    ```
    cd cis && ./cis-glb-cleanup.sh
    ```
