# About nodejs-graphql

This sample app demonstrates a sample NodeJS and GraphQL API wrapper for IBM Cloud Object Storage service and IBM Cloud Databases for PostgreSQL.
If you don't yet have an IBM Cloud account, sign up on the [registration](https://cloud.ibm.com/registration/) page.

# Pre-Requisites
  - Node.js 10.x+
  - NPM or Yarn
  - IBM Cloud Databases for PostgreSQL
  - IBM Cloud Object Storage

## Provision Databases for PostgreSQL

Databases for PostgreSQL is an IBM Cloud service. Provisioning and account management is handled through your IBM Cloud account. If you already have an account, you can provision Databases for PostgreSQL from the [IBM Cloud catalog](https://cloud.ibm.com/catalog/services/databases-for-postgresql).

For detailed provisioning information, including IBM Cloud CLI instructions, see the [Provisioning](https://cloud.ibm.com/docs/services/databases-for-postgresql?topic=cloud-databases-provisioning) page.

This app uses a PostgreSQL client driver to interact with the database.

## Setup for Databases for PostgreSQL
The app needs a file **pg_credentials.json** placed in its **config** directory. Access your Databases for PostgreSQL service instance in the IBM Cloud UI, click on **Service Credentials**. Copy that JSON structure into a new file named **pg_credentials.json**. The file needs to be placed in the **config** directory.

Another way of obtaining that JSON structure is using the IBM Cloud CLI.
1. Create a service key with role **Administrator**:
   ```
   ibmcloud resource service-key-create vpns2s-pg-key Administrator --instance-name vpns2s-pg
   ```
  
2. Obtain the service key details in JSON format and store it in a new file **credentials.json** in this subdirectory **vpc-app-cos**. The file will be used later on by the app.
   ```
   ibmcloud resource service-key vpns2s-pg-key --output json > pg_credentials.json
   ```

## Provision IBM Cloud Object Storage
Information stored with IBM® Cloud Object Storage is encrypted and dispersed across multiple geographic locations, and accessed over HTTP using a REST API. This service makes use of the distributed storage technologies provided by the IBM Cloud Object Storage System.

IBM Cloud Object Storage is available with three types of resiliency: Cross Region, Regional, and Single Data Center. Cross Region provides higher durability and availability than using a single region at the cost of slightly higher latency, and is available today in the US, EU and AP. Regional service reverses those tradeoffs, and distributes objects across multiple availability zones within a single region, and is available in the US, EU and AP regions. If a given region or availability zone is unavailable, the object store continues to function without impediment. Single Data Center distributes objects across multiple machines within the same physical location. Check here for available regions.

This app uses IBM Cloud Object Storage APIs to interact with object storage.

## Setup for IBM Cloud Object Storage
The app needs a file **cos_credentials.json** placed in its **config** directory. Access your COS service instance in the IBM Cloud UI, click on **Service Credentials**. Copy that JSON structure into a new file named **cos_credentials.json**. The file needs to be placed in the **config** directory.

Another way of obtaining that JSON structure is using the IBM Cloud CLI.
1. Create a service key with role **Writer**:
   ```
   ibmcloud resource service-key-create vpns2s-cos-key Writer --instance-name vpns2s-cos
   ```
  
2. Obtain the service key details in JSON format and store it in a new file **credentials.json** in this subdirectory **vpc-app-cos**. The file will be used later on by the app.
   ```
   ibmcloud resource service-key vpns2s-cos-key --output json > cos_credentials.json
   ```

## Getting Started

- Clone the repo.

- Install all dependencies:

    ```sh
    cd vpc-tutorials/vpc-site2site-vpn/nodejs-graphql
    npm install 
    ```

- Copy the `config/config.template.json` to `config/config.json`.

- Modify the `config/config.json` to match your settings and environment:

    ```json
    {
        "bucketName": "transactions",
        "endpoint_type": "regional",
        "region": "eu-de",
        "type": "private",
        "location": "eu-de",
        "location_constraint": "standard"
    }
    ```

- Build:

    ```sh
    npm run build
    ```


- Create the tables in the database
    ```sh
    node ./build/createTables.js
    ```

- Create the cloud object storage bucket in the database
    ```sh
    node ./build/createBucket.js
    ```

    You should see a result similar to this:
    
    ```
    Creating new bucket: transactions

    Bucket: transactions created!

    Retrieving list of buckets:
    Bucket Name: transactions
    ```

- Run the code:

    ```sh
    npm run start
    ```

- Access the server using the URI provided in the output screen.

- Copy and paste the following queries and run them each at a time, modify the balance and item_content and repeat:

```graphql
query read_database {
  read_database {
    id
    balance
    transactiontime
  }
}

query read_items {
  read_items {
    key
    size
    modified
  }
}

query read_database_and_items {
  read_database {
    id
    balance
    transactiontime
  }
  read_items {
    key
    size
    modified
  }
}

mutation add_to_database_and_storage_bucket {
  add(balance: 20.50, item_content: "Payment for movie, popcorn and drink...") {
    id
    status
  }
}
```