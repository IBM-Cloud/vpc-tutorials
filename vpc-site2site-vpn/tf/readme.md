Work in progress:  

To Do: 

 - 

If you want to enable tracing:
```sh
export TF_LOG=TRACE
```

If you want to save all activities to a log file:
```sh
export TF_LOG_PATH=config/eugb.log
```

- Copy config/accounts.tfvars.sample to config/accounts.tfvars and modify for your own values.

- Copy config/region.tfvars.sample to config/<name>.tfvars, for example eugb.tfvars and modify for your own values.

- Init providers and modules
```sh
terraform init
```

- Execute terraform plan by specifying location of variable files, state and plan file.
```sh
terraform plan -var-file=config/account.tfvars -var-file=config/eugb.tfvars -state=config/eugb.tfstate -out=config/eugb.plan
```

- Apply terraform plan by specifying location of plan file
```sh
terraform apply -state-out=config/eugb.tfstate "config/eugb.plan"
```

- Destroy resource when done by specifying location of variable files, and state file.
```sh
terraform destroy -var-file=config/account.tfvars -var-file=config/eugb.tfvars -state=config/eugb.tfstate
```

- Delete the log, plan and state files.
```sh
rm config/eugb.plan
rm config/eugb.tfstate
rm config/eugb.log
```