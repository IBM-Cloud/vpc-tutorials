# Application deploy onto a vpc instance
How to install software and files onto a Virtual Private Cloud, VPC, virtual server instance, VSI.

Here is the full [solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-app-deploy)

Each of the following examples will do the deployment as descibed in the tutorial then test the deployment and finally destroy the stuff provisioned.


First you must initialize the current shell:
```
cp export.template export
vi export; # fill in the environment variables
source export
```

To run the cli example:
```
make all_cli
```

To run the terraform example:
```
make all_tf
```

To run the ansible example:
```
make all_ansible
```
