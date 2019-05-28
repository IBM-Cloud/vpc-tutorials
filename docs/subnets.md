#### Subnets

##### Properties

- `resources_prefix`: a value that will be used when naming resources it is added to the value of the name properties with a -.
- `x_use_resources_prefix` (optional): comma separated list of resources that you do not want to add the resources prefix, i.e. vpc or subnets.
- `vpc`: parent property.
  - `subnets`: parent property.
    - `availability_zone_1`: parent property for 3 zones region (zone 1)
      - `name`: name to give the subnet.
      - `zone`: name of the zone to create the subnet.
      - `ipv4AddressCount`: maximum number of IP addresses this subnet will need to support.
      - `attachPublicGateway`: whether or not this subnet should be added to a public gateway, if set to true the pgw must previously exist in that zone. 
    - `availability_zone_2`: parent property for 3 zones region (zone 2)
      - `name`: name to give the subnet.
      - `zone`: name of the zone to create the subnet.
      - `ipv4AddressCount`: maximum number of IP addresses this subnet will need to support.
      - `attachPublicGateway`: whether or not this subnet should be added to a public gateway, if set to true the pgw must previously exist in that zone. 
    - `availability_zone_3`: parent property for 3 zones region (zone 3)
      - `name`: name to give the subnet.
      - `zone`: name of the zone to create the subnet.
      - `ipv4AddressCount`: maximum number of IP addresses this subnet will need to support.
      - `attachPublicGateway`: whether or not this subnet should be added to a public gateway, if set to true the pgw must previously exist in that zone. 

> **NOTE:** Properties not labeled informational or optional are required.

##### JSON

```json
{
  "resources_prefix": "<yourprefix>",
  "x_use_resources_prefix": "vpc,subnets",
  "vpc": [
    {
      "subnets": [
        {
          "availability_zone_1": [
            {
              "name": "sub-database-1",
              "ipv4AddressCount": "16",
              "attachPublicGateway": "true"
            },
            {
              "name": "sub-app-1",
              "ipv4AddressCount": "16",
              "attachPublicGateway": "true"
            }
          ]
        },
        {
          "availability_zone_2": [
            {
              "name": "sub-database-2",
              "ipv4AddressCount": "16",
              "attachPublicGateway": "true",
              "zone": "eu-de-2"
            },
            {
              "name": "sub-app-2",
              "ipv4AddressCount": "16",
              "attachPublicGateway": "true"
            }
          ]
        },
        {
          "availability_zone_3": [
            {
              "name": "sub-database-3",
              "ipv4AddressCount": "16",
              "attachPublicGateway": "true"
            },
            {
              "name": "sub-app-3",
              "ipv4AddressCount": "16",
              "attachPublicGateway": "true"
            }
          ]
        }
      ]
    }
  ]
}
```
