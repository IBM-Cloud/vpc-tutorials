# Automate the Creation of Boot Snapshots

## Overview

You can migrate a boot snapshot using the IBM cloud console TODO


## Create and Test a snapshot

> The scripts do not check permissions. You must ensure you have the right permissions:
> - to create VPC, subnets, instances
> - to create snapshots

All of the operations will be done in a bash shell and making use of terraform and ibmcloud command. You will find instructions to download and install these tools for your operating environment in the [Getting started with tutorials guide](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-tutorials)

To avoid the installation of these tools you can use the [Cloud Shell](https://cloud.ibm.com/shell) from the IBM Cloud console.


1. git the code and cd into this directory:

   ```sh
   git clone https://github.com/IBM-Cloud/vpc-tutorials
   cd vpc-tutorials/vpc-boot-image
   ```

1. Copy the configuration file and set the values to match your environment.

   ```sh
   cp template.local.env local.env
   ```

1. Load the values into the current shell.

   ```sh
   source local.env
   ```

1. Ensure you have the prerequisites to run the scripts.

   ```sh
   ./000-prereqs.sh
   ```
1. Run all the scripts:
   ```sh
   010-terraform-create.sh
   020-snapshot-create.sh
   030-snapshot-test.sh
   040-terraform-destroy
   ```

## Cleanup

TODO have not written this:

   ```sh
   ./050-cleanup.sh
   ```
