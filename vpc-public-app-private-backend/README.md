# Public frontend and private backend in a Virtual Private Cloud

The scripts in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-public-app-private-backend#vpc-public-app-private-backend).

| File | Description |
| ---- | ----------- |
| [vpc-pubpriv-create-with-bastion.sh](vpc-pubpriv-create-with-bastion.sh) | Create the frontend / backend sample and also provision a bastion server and security rules. The bastion is used to ssh into the frontend and backend servers. |
| [vpc-pubpriv-cleanup.sh](vpc-pubpriv-cleanup.sh) | The same as above, but the VPC name as in the tutorial is already encoded. You can specify an optional naming prefix (same as in the setup scripts). |
| [vpc-maintenance.sh](vpc-maintenance.sh) | Enable or disable maintenance mode for a given instance, adding it to the maintenance security group. |

## Resources

The following **named** resources are created by the script above:

| Resource type| Name(s) | Comments |
|--------------|------|----------|
| Virtual Private Cloud (VPC) | BASENAME | only if REUSE_VPC not present |
| Subnet | BASENAME-bastion-subnet|  |
| Subnet | BASENAME-backend-subnet| |
| Subnet | BASENAME-frontend-subnet| |
| Public Gateways | BASENAME-REGION-1-pubgw, BASENAME-REGION-2-pubgw, BASENAME-REGION-3-pubgw | one gateway in each zone,   one attached to BASENAME-backend-subnet |
| Security Group | BASENAME-bastion-sg | |
| Security Group | BASENAME-maintenance-sg | |
| Security Group | BASENAME-backend-sg | |
| Security Group | BASENAME-frontend-sg | |
| Virtual Server Instance (VSI) | BASENAME-bastion-vsi | |
| Virtual Server Instance (VSI) | BASENAME-backend-vsi | |
| Virtual Server Instance (VSI) | BASENAME-frontend-vsi | |
| Floating IP | BASENAME-bastion-ip | |
| Floating IP | BASENAME-backend-ip | |

### Terraform resource creation
The terraform configuration is in the `tf` and the `tfmodule` directories. The `tfmodule` module is re used in other tutorials.  The implementation depends on the bastion module. The BASENAME is derived from the `prefix` in the variable.tf file see main.tf:
```
locals { BASENAME = "${var.prefix}vpc-pubpriv" }
```

To create the resources:

```
cp export.template export
vi export; # make the changes suggested
source export
cd tf
terraform init
terraform plan
terraform apply
```

Clean up:
```
terraform destroy
```

## Bash resource creation

`./vpc-pubpriv-create-with-bastion.sh us-south-1 my-ssh-key myprefix myresourcegroup`

or to create into an existing VPC:

`REUSE_VPC=vpc-name ./vpc-pubpriv-create-with-bastion.sh us-south-1 my-ssh-key myprefix myresourcegroup`

Note: `myprefix` and `myresourcegroup` are optional. The zone and the name of the SSH key are mandatory for create.



Clean up a VPC identified by its name:
`../scripts/vpc-cleanup.sh <vpc-name>`

The script is going to ask for a confirmation for safety reasons.
