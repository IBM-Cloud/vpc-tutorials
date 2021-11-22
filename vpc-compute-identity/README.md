## Using Compute Identity / Instance Metadata / Trusted Profiles for SSH Keys

Use this Terraform template to provision a new Virtual Private Cloud (VPC) and Linux based Virtual Server Instance (VSI), configure IAM Trusted Profile for that instance and automate the update of SSH keys that are authorized to authenticate with the VSI.  

# Costs

When you apply this template, you are charged for the resources that you configure.

You can remove all resources created by running a terraform destroy command [described below](#delete-all-resources). Make sure that you back up any data that you wish to keep before you start the deletion process.

# Requirements

-  If you are running on a Windows operating system [install Git](https://git-scm.com/), the script is written in Bash and Git when installed on Windows will also include Git Bash that you can use to run the script.

- [Install IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cloud-cli-install-ibmcloud-cli) and required plugins:
  - infrastructure-services

- [Install jq](https://stedolan.github.io/jq/).

- [Install Terraform](https://www.terraform.io/downloads.html)

- [Download the IBM Cloud provider plugin for Terraform](https://github.com/IBM-Cloud/terraform-provider-ibm#download-the-provider-from-the-terraform-registry-option-1)

## Getting started

- Clone this repo

- From a bash terminal window change to the `vpc-compute-identity` directory.

### Build the environment in the IBM Cloud using a prepared Terraform script

- Copy the `terraform.tfvars.template` to another file called `terraform.tfvars`.
  ```sh
    cp terraform.tfvars.template terraform.tfvars
  ```

- Modify terraform.tfvars file to match your desired settings, the following properties must be set:

|  Name               | Description                         | Default Value |
| -------------------| ------------------------------------|---------------- |
| ibmcloud_api_key | An API key is a unique code that is passed to an API to identify the application or user that is calling it. To prevent malicious use of an API, you can use API keys to track and control how that API is used. For more information about API keys, see [Understanding API keys](https://cloud.ibm.com/docs/iam?topic=iam-manapikey). |
| basename | a value that will be used when naming resources it is added to the value of the name properties with a `-`, i.e. ci-vsi-1 | cockroachdb |
| region        | name of the region to create the resources. See [here](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region) for more information. | us-east |
| resource_group | name of your resource group you will be creating the resources under (must exist prior to usage) | default |

- Initialize the Terraform providers and modules. Run:
  ```sh
    terraform init
  ```

- Execute terraform plan:
  ```sh
    terraform plan 
  ```

- Apply terraform:
  ```sh
    terraform apply 
  ```

- The scripts will run to completion and you will receive an output similar to the one below, note that the number of resources added in the screenshot below may be different from what you get as it is based on revisions made to the template.  If the script were to get interrupted for any reason, you can address the error, run a plan and apply again.

- Connect to the instance from your terminal using the SSH key that was generated for you by the Terraform template
  ```sh
    ssh -i vpc-compute-identity/local/build_key_rsa root@<floating_ip>
  ```

- From your web browser go to the [IAM Trusted Profiles management page](https://cloud.ibm.com/iam/trusted-profiles) and click on the newly created profile, i.e. `<basename>-trusted-profile`.  
  - Notice in the **Trust relationship** tab the **Compute resources** section includes the VSI that was created by the Terraform template. 
  - Switch to the **Access policies** tab and click on **Assign access** to add additional SSH keys to the VSI.  
    - Click on **IAM services**
    - Select **VPC Infrastructure Services** 
    - Click on **Resources based on selected attributes** 
    - Select **Resource type** and then **SSH Key for VPC** 
    - Select **Key ID** and then pick the SSH key that you want to add to the VSI
    - Click on **Add** and then **Assign**.  
      > Note: you can add additional SSH keys if you need prior to clicking on Assign.  
  - Wait approximately 15 minutes and try to login to the VSI with the newly added SSH Key. 

 - The service that updates the authorized SSH keys writes a log file to the `/var/log/ssh-authorized-keys.log` directory on the VSI. You can view these logs when you are logged into the VSI or enable IBM Cloud Logging to capture these logs in your region.