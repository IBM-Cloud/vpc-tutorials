
## Begin Replace
- **Create Virtual Private Cloud baseline resources**
- **Create an on-premises virtual server**


### Create Virtual Private Cloud baseline resources
{: #create-vpc}
The tutorial provides a Terraform script to create the baseline resources required for this tutorial, i.e., the starting environment. The script can either generate that environment in an existing VPC or create a new VPC.

In the following, create these resources by configuring and then running a setup script. The script incorporates the setup of a bastion host as discussed in [securely access remote instances with a bastion host](https://{DomainName}/docs/tutorials?topic=solution-tutorials-vpc-secure-management-bastion-server).

1. In the directory **vpc-site2site-vpn**, copy over the sample IBM Cloud configuration file into a file to use and modify for your own values:

   ```sh
   cp config/vpns2s.tfvars.sample config/vpns2s.tfvars
   ```
   {: codeblock}

2. Edit the file **vpns2s.tfvars** and adapt the settings to your environment. You need to change the value of **softlayer_ssh_keys** and **vpc_ssh_keys** to the name or comma-separated list of names of SSH keys (see "Before you begin"). Modify the different **vpc_region** and **softlayer_datacenter** settings to match your cloud region. All other variables can be kept as is or are explained in the next section.

3. Make sure to initialize the Terraform providers and modules. Run:
   ```sh
  terraform init
   ```
   {: codeblock}

4. To create the resources, run the script as follows:
  - Execute terraform plan by specifying location of variable files, state and plan file.
  ```sh
  terraform plan -var-file=config/vpns2s.tfvars -state=config/vpns2s.tfstate -out=config/vpns2s.plan
  ```
  {: codeblock}

  - Apply terraform plan by specifying location of plan file
  ```sh
  terraform apply -state-out=config/vpns2s.tfstate config/vpns2s.plan
  ```
  {: codeblock}

5. This will result in creating the following resources, including the bastion-related resources:
   - 1 VPC
   - up to 3 public gateways, 1 per zone if not already present
   - 2 subnets within the VPC
   - 3 security groups with ingress and egress rules
   - 2 VSIs in VPC: vpns2s-cloud-vsi and vpns2s-bastion-vsi

To simulate the on-premises environment, a virtual server (VSI) is create in the classic (Softlayer) infrastructure.
   - 1 VSI: vpns2s-cloud-vsi (floating-ip is VSI_CLOUD_IP) and vpns2s-bastion (floating-ip is BASTION_IP_ADDRESS)

   Note down for later use the returned values at the console. The output is also stored in the file **config/vpns2s.tfstate**.

## End Replace


## EXTRAS 

If you want to enable tracing:
```sh
export TF_LOG=TRACE
```

If you want to save all activities to a log file:
```sh
export TF_LOG_PATH=config/vpns2s.log
```


- Destroy resource when done by specifying location of variable files, and state file.
```sh
terraform destroy -var-file=config/account.tfvars -var-file=config/eugb.tfvars -state=config/eugb.tfstate
```

- Delete the log, plan and state files.
```sh
rm config/vpns2s.plan
rm config/vpns2s.tfstate
rm config/vpns2s.log
```