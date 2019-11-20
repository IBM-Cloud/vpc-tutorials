# Migrate a Classic infrastructure instance to a VPC infrastructure instance

## Overview

You can migrate an existing *Classic* virtual server instance to VPC by capturing an image of the *Classic* virtual server instance and importing it in [*VPC Gen 1*](https://cloud.ibm.com/docs/vpc-on-classic-vsi?topic=vpc-on-classic-vsi-migrate-vsi-from-classic-infra-to-vpc-on-classic) or [*VPC Gen 2*](https://cloud.ibm.com/docs/vpc?topic=vpc-migrate-vsi-to-vpc).

The migration steps are:
1. Capture an image of a classic VSI.
1. Export the image to Cloud Object Storage.
1. Import this image into VPC custom image list.
1. Provision a VSI from this image.

The scripts in this folder show an example to migrate a CentOS VSI running in the Classic Infrastructure to a VSI running in VPC (Gen 1 or Gen 2). The scripts automate all steps you would find while going through the documentation:
1. Create a Cloud Object Storage instance and a bucket to store the captured image.
1. Set up an authorization between Cloud Object Storage and the VPC Image service.
1. Create a VSI in the Classic Infrastructure.
1. Install Nginx on the VSI so that later we can verify the new VSI also runs Nginx.
1. Capture the VSI image and wait for the image to be ready.
1. Copy the image to Cloud Object Storage.
1. Import the image into the VPC Custom Image list once the image is ready in Cloud Object Storage.
1. Provision a new VSI in VPC from this image.

## Capture a Classic VSI to VPC VSI

> The scripts do not check permissions. You must ensure you have the right permissions:
> - to create Classic virtual server instances with public network,
> - to capture Classic instance images,
> - to create Cloud Object Storage instance,
> - to create VPC, subnets, servers

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

1. Create a Cloud Object Storage instance to capture the Classic instance image and to copy it to VPC.

   ```sh
   ./010-prepare-cos.sh
   ```

1. Create a Classic virtual server instance.

   ```sh
   ./020-create-classic-vm.sh
   ```

   > The script installs Nginx on this instance. It will test that the virtual server instance is accessible through its public address and retrieve the Nginx home page.

1. Capture an image of the Classic virtual server instance.

   ```sh
   ./030-capture-classic-to-cos.sh
   ```

1. Import the captured image into VPC.

   ```sh
   ./040-import-image-to-vpc.sh
   ```

1. Create a VPC and a virtual server instance from the image.

   ```sh
   ./050-provision-vpc-vsi.sh
   ```

   > The script will test that the virtual server instance is accessible through its public address and retrieve the Nginx home page to confirm the migration worked as expected.

## Cleanup

To delete the *Classic* VSI, the Cloud Object Storage instance, the images, the VPC, run:

   ```sh
   ./060-cleanup.sh
   ```
