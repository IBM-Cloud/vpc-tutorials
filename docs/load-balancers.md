#### Load Balancers

##### Properties

- `resources_prefix`: a value that will be used when naming resources it is added to the value of the name properties with a -.
- `x_use_resources_prefix` (optional): comma separated list of resources that you do not want to add the resources prefix, i.e. vpc or load_balancers.
- `vpc`: parent property.
  - `load_balancers`: parent property.
    - `name`: name to give the load balancer.
    - `type`: values can be private or public.
    - `subnets`: an array of the subnet names that should be added to the load balancer
    - `pools`: 
      - `members`:
          - `name`: name of the instance to add to the load balancer.

> **NOTE:** Properties not labeled informational or optional are required.

> **NOTE:** Properties not listed above are same as would be found in the CLI results when reading a load balancer details.

##### JSON

```json
{
  "resources_prefix": "<yourprefix>",
  "vpc": [
    {
      "load_balancers": [
        {
          "name": "lb-private",
          "type": "private",
          "subnets": ["sub-database-1", "sub-database-2", "sub-database-3"],
          "pools": [
            {
              "name": "database",
              "algorithm": "round_robin",
              "protocol": "tcp",
              "health_monitor": {
                "url_path": "/health",
                "type": "tcp",
                "delay": 5,
                "max_retries": 2,
                "timeout": 2
              },
              "members": [
                {
                  "port": 26257,
                  "name": "vsi-database-1"
                },
                {
                  "port": 26257,
                  "name": "vsi-database-2"
                },
                {
                  "port": 26257,
                  "name": "vsi-database-3"
                }
              ]
            }
          ],
          "listeners": [
            {
              "port": 26257,
              "protocol": "tcp"
            }
          ]
        },
        {
          "name": "lb-public",
          "type": "public",
          "subnets": ["sub-app-1", "sub-app-2", "sub-app-3"],
          "pools": [
            {
              "name": "app",
              "algorithm": "round_robin",
              "protocol": "http",
              "health_monitor": {
                "url_path": "/health",
                "type": "http",
                "delay": 5,
                "max_retries": 2,
                "timeout": 2
              },
              "members": [
                {
                  "port": 5000,
                  "name": "vsi-app-1"
                }
              ]
            }
          ],
          "listeners": [
            {
              "port": 80,
              "protocol": "http"
            }
          ]
        }
      ]
    }
  ]
}
```
