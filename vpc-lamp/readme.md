- Initialize the Terraform providers and modules. Run:
```sh
terraform init
```

- Execute terraform plan by specifying location of variable files, state and plan file:
```sh
terraform plan -var-file=config/lamp.tfvars -state=config/lamp.tfstate -out=config/lamp.plan
```

- Apply terraform plan by specifying location of plan file:
```sh
terraform apply -state-out=config/lamp.tfstate config/lamp.plan
```

- Delete all resources
```
terraform destroy -var-file=config/lamp.tfvars -state=config/lamp.tfstate
```