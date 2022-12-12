# Public frontend and private backend in a Virtual Private Cloud

The Terraform template in this directory can be used to deploy or clean up the resources for the [IBM Cloud solution tutorial](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-public-app-private-backend#vpc-public-app-private-backend).

## Terraform resource creation
The terraform configuration is in the `tf` and the `tfmodule` directories. The `tfmodule` module is re used in other tutorials. The implementation depends on the bastion module. The BASENAME is derived from the `prefix` in the variable.tf file see main.tf:
```
locals { BASENAME = "${var.prefix}vpc-pubpriv" }
```

To create the resources:

```
cd tf
cp export.template export
vi export; # make the changes suggested
source export
terraform init
terraform plan
terraform apply
```

Clean up:
```
terraform destroy
```

## Resources

The following **named** resources are created by the Terraform template above:

| Resource type| Name(s) | Comments |
|--------------|------|----------|
| Virtual Private Cloud (VPC) | BASENAME-pubpriv | only if REUSE_VPC not present |
| Subnet | BASENAME-pubpriv-bastion-subnet|  |
| Subnet | BASENAME-pubpriv-backend-subnet| |
| Subnet | BASENAME-pubpriv-frontend-subnet| |
| Security Group | BASENAME-pubpriv-bastion-sg | |
| Security Group | BASENAME-pubpriv-maintenance-sg | |
| Security Group | BASENAME-pubpriv-backend-sg | |
| Security Group | BASENAME-pubpriv-frontend-sg | |
| Virtual Server Instance (VSI) | BASENAME-pubpriv-bastion-vsi | |
| Virtual Server Instance (VSI) | BASENAME-pubpriv-backend-vsi | |
| Virtual Server Instance (VSI) | BASENAME-pubpriv-frontend-vsi | |
| Floating IP | BASENAME-pubpriv-bastion-ip | |
| Floating IP | BASENAME-pubpriv-backend-ip | |