### Gateways

##### Properties

- `resources_prefix`: a value that will be used when naming resources it is added to the value of the name properties with a -.
- `x_use_resources_prefix` (optional): comma separated list of resources that you do not want to add the resources prefix, i.e. vpc or public_gateways.
- `vpc`: parent property.
  - `public_gateways`: parent property.
    - `name`: name to give the public gateway.
    - `zone`: name of the zone to attach to the public gateway.

>**NOTE:** Properties not labeled informational or optional are required.

##### JSON

```json
{
  "resources_prefix": "<yourprefix>",
  "x_use_resources_prefix": "vpc,subnets,public_gateways",
  "vpc": [
   {
      "public_gateways": [
        {
          "name": "pgw-zone1",
          "zone": "eu-de-1"
        },
        {
          "name": "pgw-zone2",
          "zone": "eu-de-2"
        },
        {
          "name": "pgw-zone3",
          "zone": "eu-de-3"
        }
      ]
   }
 ]
}
```