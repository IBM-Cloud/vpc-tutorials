# Application deploy onto a vpc instance
This directory is a companion to the IBM Cloud solution tutorial [Install software on virtual server instances in VPC
](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-app-deploy).

Each of the following examples will do the deployment as described in the tutorial then test the deployment and finally destroy the stuff provisioned.


First you must initialize the current shell:
```
cp export.template export
vi export; # fill in the environment variables
source export
```

Now you can test out the steps in the tutorial using `make TYPE_COMMAND`
- TYPE - cli, tf, a for cli, terraform or ansible
- COMMAND:
  - apply - just create the resourcews
  - apply_test - apply and test the resources
  - all - apply, test and then destroy the resources.

To run the cli example from start to finish:
```
make cli_all
```

To run the terraform example from start to finish:
```
make tf_all
```

To run the ansible example from start to finish, ansible must be on your PATH:
```
make a_all
```
