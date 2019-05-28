#### Virtual Servers

##### Properties

- `vpc`: parent property.
  - `virtualServerInstances`: parent property.
    - `name`: name to give the instance.
    - `zone`: name of the zone to create the instance.
    - `security_groups`: array of security groups to attach to the instance.
    - `type`: whether or not this subnet should be added to a public gateway, if set to true the pgw must previously exist in that zone.
    - `cloud_init`: the name of a shell script that will be attached to the create of the instance, it runs the first time the instance boots up. It must exist under the scripts/cloud-init folder.
    - `ssh_init`: the name of a shell script that will run after the instance is stated. It must exist under the scripts/ssh-init folder.
    - `data_volume`:
      - `name`: the name of the data volume to create, note if this is supplied the key protect section must exist in the config file as the volume requires it for encryption.

> **NOTE:** Properties not labeled informational or optional are required.

> **NOTE:** Properties not listed above are same as would be found in the CLI results when reading a load balancer details.

##### JSON

```json
{
  "resources_prefix": "<yourprefix>",
  "vpc": [
    {
      "virtualServerInstances_section_help": "",
     "virtual_server_instances": [
        {
          "name": "vsi-database-1",
          "image_name": "ubuntu-18.04-amd64",
          "profile_name": "c-2x4",
          "primary_subnet": "sub-database-1",
          "port_speed": 1000,
          "security_groups": ["sg-database"],
          "type": "cockroachdb",
          "cloud_init": "cockroachdb-basic-systemd.sh",
          "ssh_init": "cockroachdb.sh",
          "data_volume": {
            "name": "attachment-data-1",
            "volume": {
              "name": "cockroach-data-1",
              "capacity": 100,
              "profile": {
                "name": "10iops-tier"
              }
            },
            "delete_volume_on_instance_delete": true
          }
        },
        {
          "name": "vsi-database-2",
          "image_name": "ubuntu-18.04-amd64",
          "profile_name": "c-2x4",
          "primary_subnet": "sub-database-2",
          "port_speed": 1000,
          "security_groups": ["sg-database"],
          "type": "cockroachdb",
          "cloud_init": "cockroachdb-basic-systemd.sh",
          "ssh_init": "cockroachdb.sh",
          "data_volume": {
            "name": "attachment-data-2",
            "volume": {
              "name": "cockroach-data-2",
              "capacity": 100,
              "profile": {
                "name": "10iops-tier"
              }
            },
            "delete_volume_on_instance_delete": true
          }
        },
        {
          "name": "vsi-database-3",
          "image_name": "ubuntu-18.04-amd64",
          "profile_name": "c-2x4",
          "primary_subnet": "sub-database-3",
          "port_speed": 1000,
          "security_groups": ["sg-database"],
          "type": "cockroachdb",
          "cloud_init": "cockroachdb-basic-systemd.sh",
          "ssh_init": "cockroachdb.sh",
          "data_volume": {
            "name": "attachment-data-3",
            "volume": {
              "name": "cockroach-data-3",
              "capacity": 100,
              "profile": {
                "name": "10iops-tier"
              }
            },
            "delete_volume_on_instance_delete": true
          }
        },
        {
          "name": "vsi-admin",
          "zone": "eu-de-1",
          "image_name": "ubuntu-18.04-amd64",
          "profile_name": "c-2x4",
          "primary_subnet": "sub-database-1",
          "port_speed": 1000,
          "security_groups": ["sg-admin"],
          "type": "cockroachdb-admin",
          "cloud_init": "cockroachdb-admin-systemd.sh",
          "ssh_init": "cockroachdb-admin.sh",
          "floating_ip": {
            "name": "fip-1"
          }
        },
        {
          "name": "vsi-app-1",
          "image_name": "ubuntu-18.04-amd64",
          "profile_name": "c-2x4",
          "primary_subnet": "sub-app-1",
          "port_speed": 1000,
          "type": "app",
          "cloud_init": "deployapp.sh"
        }
      ]
    }
  ]
}
```
