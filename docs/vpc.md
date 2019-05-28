#### Parent and VPC

##### Properties

- `description`: what this configuration is used for (informational).
- `x_use_resources_prefix` (optional): comma separated list of resources that you do not want to add the resources prefix, i.e. vpc.
- `resources_prefix`: a value that will be used when naming resources it is added to the value of the name properties with a -.
- `region`: name of the region to create the resources.
- `resource_group`: name of your resource group you will be creating the resources under (must exist prior to usage).
- `vpc`: parent property.
  - `name`: name to give the VPC.
  - `use_resources_prefix`: add this property and set the value to false to not use the resources_prefix even if it is provided above  (optional).

>**NOTE:** Properties not labeled informational or optional are required.

##### JSON

```json
{
  "description": "Creates a 6 vsi, 3 zones cockroachdb cluster inside a VPC with a customer controlled key encrypted data Block Storage",
  "resources_prefix": "<yourprefix>",
  "x_use_resources_prefix": "vpc",
  "region": "eu-de",
  "resource_group": "default",
  "vpc": [
    {
      "name": "vpc-fra"
    }
  ]
}
```

>**NOTE:** The `vpc` is an array, however do not attempt to create multiple VPCs with a single configuration file.