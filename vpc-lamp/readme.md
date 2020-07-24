## PHP web application on a LAMP Stack in VPC
The templates in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-lamp-stack-on-vpc).

- Copy the config-template directory to another directory called config.
  ```sh
    cp -a config-template config
  ```

- Modify config/lamp.sh file to match your desired settings and place in a directory of your choice, the following properties must be set:

|  Name               | Description                         | Default Value |
| -------------------| ------------------------------------|---------------- |
| TF_VAR_ibmcloud_api_key | An API key is a unique code that is passed to an API to identify the application or user that is calling it. To prevent malicious use of an API, you can use API keys to track and control how that API is used. For more information about API keys, see [Understanding API keys](https://cloud.ibm.com/docs/iam?topic=iam-manapikey). |
| TF_VAR_resources_prefix | a value that will be used when naming resources it is added to the value of the name properties with a `-` | lamp |
| TF_VAR_vpc_region        | name of the region to create the resources, currently it can be a choice between `au-syd`, `us-south`, `eu-de` , `eu-gb` or `jp-tok`. See [here](https://cloud.ibm.com/docs/vpc-on-classic-vsi?topic=vpc-on-classic-vsi-faqs#what-regions-are-available-) for more information. | us-south |
| TF_VAR_resource_group | name of your resource group you will be creating the resources under (must exist prior to usage) | default |
| TF_VAR_vpc_ssh_key | Existing SSH key name for in region access to VSIs after creation, you must create at least one if you do not already have any. More information on creating SSH keys is available in the [product documentation](https://cloud.ibm.com/docs/vpc-on-classic-vsi?topic=vpc-on-classic-vsi-ssh-keys). |
| TF_VAR_ssh_private_key | Location of your SSH private key | ~/.ssh/id_rsa |
| TF_VAR_byok_data_volume | Set to true to create a Data Volume encrypted with and Root Key that is stored in Key Protect | false |


- Execute the following command to add the values to your environment:
```sh
source config/lamp.sh
```

- Initialize the Terraform providers and modules. Run:
```sh
terraform init
```

- Execute terraform plan by specifying location of variable files, state and plan file:
```sh
terraform plan -state=config/lamp.tfstate -out=config/lamp.plan
```

- Apply terraform plan by specifying location of plan file:
```sh
terraform apply -state-out=config/lamp.tfstate config/lamp.plan
```

- Delete all resources
```
terraform destroy -state=config/lamp.tfstate
```