#### Security Groups

##### Properties

- `resources_prefix`: a value that will be used when naming resources it is added to the value of the name properties with a -.
- `x_use_resources_prefix` (optional): comma separated list of resources that you do not want to add the resources prefix, i.e. vpc or security_groups.
- `vpc`: parent property.
  - `security_groups`: parent property.
    - `name`: name to give the security group.
    - `rules`:
      - `direction`:
      - `remote`: name of the instance to add to the load balancer.
        - `key`: can be lookup, group or cidr, the value then needs to match in the order below.
        - `value`: can be the name of a subnet to lookup, the name of another security group or a cidr.

> **NOTE:** Properties not labeled informational or optional are required.

> **NOTE:** Properties not listed above are same as would be found in the CLI results when reading a load balancer details.

##### JSON

```json
{
  "resources_prefix": "<yourprefix>",
  "vpc": [
    {
      "security_groups": [
        {
          "name": "sg-database",
          "description": "",
          "rules": [
            {
              "direction": "inbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone1-db"
              },
              "protocol": "tcp",
              "port_min": 26257,
              "port_max": 26257
            },
            {
              "direction": "inbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone2-db"
              },
              "protocol": "tcp",
              "port_min": 26257,
              "port_max": 26257
            },
            {
              "direction": "inbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone3-db"
              },
              "protocol": "tcp",
              "port_min": 26257,
              "port_max": 26257
            },
            {
              "direction": "inbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone1-db"
              },
              "protocol": "tcp",
              "port_min": 8080,
              "port_max": 8080
            },
            {
              "direction": "inbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone2-db"
              },
              "protocol": "tcp",
              "port_min": 8080,
              "port_max": 8080
            },
            {
              "direction": "inbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone3-db"
              },
              "protocol": "tcp",
              "port_min": 8080,
              "port_max": 8080
            },
            {
              "direction": "inbound",
              "remote": {
                "key": "group",
                "value": "sg-admin"
              },
              "protocol": "tcp",
              "port_min": 22,
              "port_max": 22
            },
            {
              "direction": "inbound",
              "remote": {
                "key": "group",
                "value": "sg-admin"
              },
              "protocol": "tcp",
              "port_min": 8080,
              "port_max": 8080
            },
            {
              "direction": "inbound",
              "remote": {
                "key": "group",
                "value": "sg-admin"
              },
              "protocol": "tcp",
              "port_min": 26257,
              "port_max": 26257
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "cidr",
                "value": "0.0.0.0/0"
              },
              "protocol": "tcp",
              "port_min": 53,
              "port_max": 53
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "cidr",
                "value": "0.0.0.0/0"
              },
              "protocol": "udp",
              "port_min": 53,
              "port_max": 53
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "cidr",
                "value": "0.0.0.0/0"
              },
              "protocol": "tcp",
              "port_min": 443,
              "port_max": 443
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "cidr",
                "value": "0.0.0.0/0"
              },
              "protocol": "tcp",
              "port_min": 80,
              "port_max": 80
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "address",
                "value": "216.239.35.0"
              },
              "protocol": "udp",
              "port_min": 123,
              "port_max": 123
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "address",
                "value": "216.239.35.4"
              },
              "protocol": "udp",
              "port_min": 123,
              "port_max": 123
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "address",
                "value": "216.239.35.8"
              },
              "protocol": "udp",
              "port_min": 123,
              "port_max": 123
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "address",
                "value": "216.239.35.12"
              },
              "protocol": "udp",
              "port_min": 123,
              "port_max": 123
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone1-db"
              },
              "protocol": "tcp",
              "port_min": 26257,
              "port_max": 26257
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone2-db"
              },
              "protocol": "tcp",
              "port_min": 26257,
              "port_max": 26257
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "lookup",
                "value": "sub-zone3-db"
              },
              "protocol": "tcp",
              "port_min": 26257,
              "port_max": 26257
            }
          ]
        },
        {
          "name": "sg-admin",
          "description": "",
          "rules": [
            {
              "direction": "inbound",
              "remote": {
                "key": "address",
                "value": "71.185.55.148"
              },
              "protocol": "tcp",
              "port_min": 22,
              "port_max": 22
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "group",
                "value": "sg-database"
              },
              "protocol": "tcp",
              "port_min": 22,
              "port_max": 22
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "group",
                "value": "sg-database"
              },
              "protocol": "tcp",
              "port_min": 8080,
              "port_max": 8080
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "group",
                "value": "sg-database"
              },
              "protocol": "tcp",
              "port_min": 26257,
              "port_max": 26257
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "cidr",
                "value": "0.0.0.0/0"
              },
              "protocol": "tcp",
              "port_min": 53,
              "port_max": 53
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "cidr",
                "value": "0.0.0.0/0"
              },
              "protocol": "udp",
              "port_min": 53,
              "port_max": 53
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "cidr",
                "value": "0.0.0.0/0"
              },
              "protocol": "tcp",
              "port_min": 443,
              "port_max": 443
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "cidr",
                "value": "0.0.0.0/0"
              },
              "protocol": "tcp",
              "port_min": 80,
              "port_max": 80
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "address",
                "value": "216.239.35.0"
              },
              "protocol": "udp",
              "port_min": 123,
              "port_max": 123
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "address",
                "value": "216.239.35.4"
              },
              "protocol": "udp",
              "port_min": 123,
              "port_max": 123
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "address",
                "value": "216.239.35.8"
              },
              "protocol": "udp",
              "port_min": 123,
              "port_max": 123
            },
            {
              "direction": "outbound",
              "remote": {
                "key": "address",
                "value": "216.239.35.12"
              },
              "protocol": "udp",
              "port_min": 123,
              "port_max": 123
            }
          ]
        }
      ]
    }
  ]
}
```
