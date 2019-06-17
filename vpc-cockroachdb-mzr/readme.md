## Deploying CockroachDB in a Multi-Zoned Virtual Private Cloud with Encrypted Block Storage

### Build the environment in the IBM Cloud using a prepared shell script and template configuration
          
- Create a configuration file to match your desired settings and place in a directory of your choice, the following properties must be set: 

    `resources_prefix`: a value that will be used when naming resources it is added to the value of the name properties with a `-`, i.e. cockroach-vsi-database-1.

    `region`:  name of the region to create the resources, currently it can be a choice between `us-south`, `eu-de` or `jp-tok`. See [here](https://cloud.ibm.com/docs/vpc-on-classic-vsi?topic=vpc-on-classic-vsi-faqs#what-regions-are-available-) for more information. 

    `resource_group`: name of your resource group you will be creating the resources under (must exist prior to usage), i.e. `default`
    
    `ssh_keys`: Existing SSH key name(s) for in region access to VSIs after creation, you must create at least one if you do not already have any. More information on creating SSH keys is available in the [product documentation](https://cloud.ibm.com/docs/vpc-on-classic-vsi?topic=vpc-on-classic-vsi-ssh-keys).

    Example version: 

    ```json
    {
    "resources_prefix": "cockroach",
    "region": "eu-de",
    "resource_group": "default",
    "ssh_keys": [
        {
        "name": "ssh-cockroach-admin",
        "type": "vpc"
        }
    ]
    }
    ```

- run the script
```
./build.sh --template=vpc-cockroachdb-mzr/vpc-cockroachdb-mzr.template.json --config=<your_config_file>.json
```

- Review the results of running the script and connect to the instances created (IP addresses and hostnames in the screen shot are examples only and will be different for you.)

    ![](./docs/images/script_summary.png)


### Test the cluster (taken from the CockroachDB documentation)

1.	SSH into the admin instance.
    
    admin instance
    ```
    ssh -F vpc-cockroachdb-mzr/ssh-init/ssh.config root@<admin_instance_ip>
    ```

2.  Using the internal IP address of node 1, issue the following command:
    ```
    cockroach sql --certs-dir=/certs --host=<IP address node>
    ```

3.  Run the following CockroachDB SQL statements:

    ```sql
    CREATE USER IF NOT EXISTS maxroach;
    ```

    ```sql
    CREATE DATABASE bank;
    ```

    ```sql
    GRANT ALL ON DATABASE bank TO maxroach;
    ```

    ```sql
    CREATE TABLE bank.accounts (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), transactiontime TIMESTAMPTZ DEFAULT current_timestamp(),  balance DECIMAL);
    ```

    ```sql
    INSERT INTO bank.accounts (balance) VALUES (1000.50);
    ```

    ```sql
    SELECT * FROM bank.accounts;
    ```

    ```
    +----+---------+
    | id | balance |
    +----+---------+
    |  e915b462-f415-4b67-bd0d-fd22a68a62a5 |  1000.5 |
    +----+---------+
    (1 row)
    ```

4.  Exit the SQL shell on node 1:

    ```sql
    \q
    ```

5.  Then connect the SQL shell to node 2, this time specifying the node's non-default port:

    ```shell
    $ cockroach sql --certs-dir=/certs --host=<IP address node>
    ```

6. Now run the same `SELECT` query:

    ```sql
    SELECT * FROM bank.accounts;
    ```

    ```
    +----+---------+
    | id | balance |
    +----+---------+
    |  e915b462-f415-4b67-bd0d-fd22a68a62a5 |  1000.5 |
    +----+---------+
    (1 row)
    ```

    ```sql
    INSERT INTO bank.accounts (balance) VALUES (100.75);
    ```

7. Exit the SQL shell on node 2:

    ```sql
    \q
    ```

8. Repeat the same steps used for node 2 above for node 3, but change the insert to the one below:

    ```sql
    INSERT INTO bank.accounts (balance) VALUES (50.00);
    ```

## Try a small application

1.  Open your browser and navigate the to the public load balancer address: http://<public_lb>/api/bank.

2.	Copy and paste the following queries:
  
```graphql
query read {
    read{
    id
    balance
    transactiontime
    }
}

mutation add {
    add(balance:"220"){
    rowCount
    }
}
```

4.	Execute a few read(s) and an add(s) while changing the value for the balance to validate entries are added. 

## Monitor the cluster

On accessing the Admin UI, your browser will consider the CockroachDB-created certificate invalid, so you’ll need to click through a warning message to get to the UI. For secure clusters, you can avoid getting the warning message by using a certificate issued by a public CA. 

For each user who should have access to the Admin UI for a secure cluster, create a user with a password. 

1. Configure a web proxy to admin server and SSH into the admin instance,
    ```
    ssh -F vpc-cockroachdb-mzr/ssh-init/ssh.config -L 8080:<address of any node>:8080 root@<admin_instance_ip>
    ```
    
2.  Using the internal IP address of node 1, issue the following command:
    ```
    cockroach sql --certs-dir=/certs --host=<IP address node>
    ```

3.  Run the following CockroachDB SQL statements:

    ```sql
    CREATE USER IF NOT EXISTS uiadmin WITH PASSWORD '<a password>';
    ```

4. Access the Admin UI for your cluster by pointing a browser to `http://localhost:8080`. 

    ![](./docs/images/cluster_overview.png)

    Then click **Metrics** on the left-hand navigation bar.

    As mentioned earlier, CockroachDB automatically replicates your data behind-the-scenes. To verify that data written in the previous step was replicated successfully, scroll down to the **Replicas per Node** graph and hover over the line:

    ![](./docs/images/metrics_overview.png)
    
    The replica count on each node is identical, indicating that all data in the cluster was replicated 3 times (the default).

## Delete all resources

Running the following script will delete all resources listed inside of the myconfig.state.json, recall it was created earlier during the build process based on the myconfig.json file provided during the build process.  Please note it will also delete the Key Protect store and stored encryption keys, as well as the Certificate Manager and all the certs used by the cockroach instances.

```
./delete.sh --template=vpc-cockroachdb-mzr/vpc-cockroachdb-mzr.template.json --config=<your_config_file>.json
```

>NOTE
> 
> - If any errors are encountered during the script execution, you can run the script again, it will skip resources already deleted and pick up where it left off.
>
> - create a log file by adding the `--createLogFile` parameter to the above command.
>
> - add shell trace and IBMCLOUD_TRACE=true by adding the `--trace`  parameter to the above command.
 
## Reference our tutorials

- Leverage the following tutorials to build the resources as depicted in the diagram under the [Environment Overview](#environment-overview) section. 
    - [Private and public subnets in a Virtual Private Cloud](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-public-app-private-backend)

    - [Deploy isolated workloads across multiple locations and zones](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-multi-region)

    - [Creating block storage volumes in IBM Cloud console](https://cloud.ibm.com/docs/infrastructure/block-storage-is?topic=block-storage-is-creating-block-storage&topicid=block-storage-is-block-storage-getting-started)

    - [Securely access remote instances with a bastion host](https://cloud.ibm.com/docs/tutorials?topic=solution-tutorials-vpc-secure-management-bastion-server)

    - [Deploy CockroachDB](https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-premises-insecure.html#systemd) leveraging the documentation from CockroachDB for on-premises deployment. One difference is we will us the load balancer provided in the IBM Cloud VPC rather than installing the HA Proxy. 


### FAQ

- What do I do if the script fails during execution?
 - Every time the script runs it creates a new file that contains all state information and the file is based on the name of the config file you provided and stored in the same directory, i.e. if --config=myconfig.json a new file is created called myconfig.state.json in the same directory. You will require the myconfig.state.json to delete the resources later.  
 - If any errors are encountered during the script execution, you can run the script again, it will skip resources already created and pick up where it left off.
 - create a log file by adding the `--createLogFile` parameter to the above command.
 - add shell trace and IBMCLOUD_TRACE=true by adding the `--trace`  parameter to the above command.

## Detail diagram of deployment via config template

![](./docs/diagrams/cockroachdb-mzr.png)

>**Note 1:** Load Balancers (LBaaS) and Public Gateways (PGW) are available across region with redundancy and auto-scale based on load and are IBM Cloud managed.

>**Note 2:** PGW are for outbound Internet access only, no inbound allowed unless it is a response to outbound request.

>**Note 3:** The data volumes are not shared as the database engine will handle data replication between the nodes. If the application requires it they can be shared.

>**Note 4:** The load balancers to the database instances have an internal only egress and will not accept any connections outside of the VPC.

>**Note 5:** The load balancer to the application instances are public and have an external egress, customer can also use their own address if desired.