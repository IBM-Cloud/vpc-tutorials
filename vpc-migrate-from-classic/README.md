# Migrate a Classic infrastructure instance to a VPC infrastructure instance

## Overview

You can migrate an existing *Classic* virtual server instance to a *VPC on Classic* virtual server instance by capturing an image of the *Classic* virtual server instance and creating a new virtual server instance in *VPC on Classic*.

The migration steps are:
1. Capture an image of a classic VSI.
1. Export the image to Cloud Object Storage.
1. Import this image into VPC custom image list.
1. Provision a VSI from this image.

The scripts in this folder show an example to migrate a CentOS VSI running in *Classic* to a VSI running in *VPC on Classic*. The scripts automate all steps:
1. Create a Cloud Object Storage instance and bucket.
1. Set up the authorization between Cloud Object Storage and the VPC Image service.
1. Create a VSI in *Classic*.
1. Capture the VSI image and wait for the image to be ready.
1. Copy the image to Cloud Object Storage.
1. Import the image into the VPC custom image list once the image is in Cloud Object Storage.
1. Provision a new VSI in *VPC on Classic* from this image.

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
