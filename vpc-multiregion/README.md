# Instructions

1. Open the terminal and add your SSH key

    ```
    ssh-add -K ~./ssh/<YOUR_PRIVATE_KEY>
    ```

1. Navigate to `vpc-multiregion` folder in the repo and create a `.env` file from the template

   ```
    cd vpc-multiregion
    cp template.env .env
   ```

1. Provide the required details in the `.env` file and save.
1. Execute the shell script and follow the steps of execution to setup VPCs in multiple regions in ONE-GO

    ```
    ./vpc-multiregion-create.sh
    ```
1. For creating VPC resources in a single regions, run this script
    ```
    ./vpc-multiregion-region-create <REGION_NAME>
    ```
1. Update the `.env` file with the `hostnames` returned by the above scripts and run the below script to create a Global Load Balancer(GLB)
    ```
    cd cis
    ./cis-glb-create.sh
    ```
### Cleanup
1. To delete VPC resources
     ```
      cd scripts
      ./vpc-cleanup.sh
     ```
1. To delete CIS resources
    ```
    cd cis
    ./cis-glb-cleanup.sh
    ```