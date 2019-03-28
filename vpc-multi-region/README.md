# Deploy isolated workloads across multiple locations and zones

The scripts in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-multi-region#vpc-multi-region).

| File | Description |
| ---- | ----------- |
| [vpc-multi-region-single-create.sh](vpc-multi-region-single-create.sh) | Creates VPC resources in a single region. |
| [vpc-multi-region-create.sh](vpc-multi-region-create.sh) | Creates VPC resources in multiple regions. |
| [vpc-multi-region-cleanup.sh](vpc-multi-region-cleanup.sh) | Removes all created resources. |
| [cis/cis-glb-create.sh](cis/cis-glb-create.sh) | Configures a global load balancer. |

## Instructions

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
1. Update the `.env` file with the `hostnames` returned by the above scripts and run the below script to create a Global Load Balancer(GLB)
    ```
    cd cis
    ./cis-glb-create.sh
    ```
### Cleanup

Run the below script to delete CIS GLB resources and VPC resources in ONE-GO

    ./vpc-multi-region-cleanup.sh <VPC_NAME> <LOAD_BALANCER_NAME>
