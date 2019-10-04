# Application deploy onto a vpc instance
How to install software and files onto a Virtual Private Cloud, VPC, virtual server instance, VSI.

Here is the full [solution tutorial](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-app-deploy)

Each of the following examples will do the deployment as descibed in the tutorial then test the deployment and finally destroy the stuff provisioned.


First you must initialize the current shell:
```
cp export.template export
vi export; # fill in the environment variables
source export
ibmcloud is target --gen 1; # 1 for generation classic, 2 for vpc available soon
```

To run the cli example:
```
make cli_all
```

To run the terraform example:
```
make tf_all
```

To run the ansible example, ansible must be on your PATH:
```
make a_all
```
