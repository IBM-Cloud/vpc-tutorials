# VPC Tutorials - Scripts
The scripts in this repo use the IBM Cloud CLI to set up scenarios for VPC tutorials and to clean up VPC resources.

- vpc-cleanup.sh: General cleanup script. Provide the VPC name to delete all related resources
- vpc-pubpriv-cleanup.sh: The same as above, but the VPC name as in the tutorial is already encoded. You can specify an optional naming prefix (same as in the setup scripts).
- vpc-pubpriv-create.sh: Create the frontend / backend sample, no bastion server included.
- vpc-pubpriv-create-with-bastion.sh: Create the frontend / backend sample and also provision a bastion server and security rules. The bastion is used to ssh into the frontend and backend servers.

### Usage
`./vpc-pubpriv-create.sh us-south-1 my-ssh-key myprefix`

`./vpc-pubpriv-create-with-bastion.sh us-south-1 my-ssh-key myprefix`

`./vpc-pubpriv-cleanup.sh myprefix`

Note: `myprefix` is optional. The zone and the name of the SSH key are mandatory for create.


Clean up a VPC identified by its name:
`./vpc-cleanup.sh VPC-name`   

The script is going to ask for a confirmation for safety reasons.
