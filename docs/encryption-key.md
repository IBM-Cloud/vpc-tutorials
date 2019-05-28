#### Encryption Key

##### Properties

- `resources_prefix`: a value that will be used when naming resources it is added to the value of the name properties with a -.
- `vpc`: parent property.
- `service_instances`: parent property.
    - `name`: name of the service (must exist prior to usage).
    - `service_name`: type of service, i.e. kms=key_protect, 
    - `key_name`: name of the encryption key (must exist prior to usage).
    - `service_plan_name`: 

> **NOTE:** Properties not labeled informational or optional are required.

##### JSON

```json
{
  "resources_prefix": "<yourprefix>",
  "vpc": [{}],
  "service_instances": [
    {
      "name": "kp-data",
      "service_name": "kms",
      "service_plan_name": "tiered-pricing",
      "authorizations": [
        {
          "service_name": "server-protect",
          "roles": [
            {
              "name": "Reader"
            }
          ]
        }
      ],
      "keys": [
        {
          "name": "key-data"
        }
      ]
    }
  ]
}
```
