- Initialize the Terraform providers and modules. Run:
```sh
terraform init
```

- Execute terraform plan by specifying location of variable files, state and plan file:
```sh
terraform plan -var-file=config/database-app-mzr.tfvars -state=config/database-app-mzr.tfstate -out=config/database-app-mzr.plan
```

- Apply terraform plan by specifying location of plan file:
```sh
terraform apply -state-out=config/database-app-mzr.tfstate config/database-app-mzr.plan
```

- Destroy
```
terraform destroy -var-file=config/database-app-mzr.tfvars -state=config/database-app-mzr.tfstate
```
