# nodejs-graphql

# Simple app to add and show files from IBM Cloud Object Storage service

This sample app demonstrates a sample GraphQL API wrapper for the IBM Cloud Object Storage service and IBM Cloud Databases for PostgreSQL.

## Setup for Cloud Object Storage
The app needs a file **cos_credentials.json** placed in its app directory. Access your COS service instance in the IBM Cloud UI, click on **Service Credentials**. Copy that JSON structure into a new file named **cos_credentials.json**. The file needs to be placed in the **config** directory.

Another way of obtaining that JSON structure is using the IBM Cloud CLI.
1. Create a service key with role **Writer**:
   ```
   ibmcloud resource service-key-create vpns2s-cos-key Writer --instance-name vpns2s-cos
   ```
  
2. Obtain the service key details in JSON format and store it in a new file **credentials.json** in this subdirectory **vpc-app-cos**. The file will be used later on by the app.
   ```
   ibmcloud resource service-key vpns2s-cos-key --output json > cos_credentials.json
   ```

## Setup for ICD for PostgreSQL
The app needs a file **pg_credentials.json** placed in its app directory. Access your ICD for PostgreSQL service instance in the IBM Cloud UI, click on **Service Credentials**. Copy that JSON structure into a new file named **pg_credentials.json**. The file needs to be placed in the **config** directory.

Another way of obtaining that JSON structure is using the IBM Cloud CLI.
1. Create a service key with role **Reader**:
   ```
   ibmcloud resource service-key-create vpns2s-pg-key Administrator --instance-name vpns2s-pg
   ```
  
2. Obtain the service key details in JSON format and store it in a new file **credentials.json** in this subdirectory **vpc-app-cos**. The file will be used later on by the app.
   ```
   ibmcloud resource service-key vpns2s-pg-key --output json > pg_credentials.json
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

- Run the code:

    ```sh
    npm run start
    ```

- Access the server using the uri provided in the output screen.

- Copy and paste the following queries:

```graphql
query read_database {
  read_database {
    id
    balance
    transactiontime
  }
}

query read_storage {
  read_storage {
    key
    size
    modified
  }
}

mutation add {
  add(balance: "22.50", fileText: "Payment for movie, popcorn and drink...") {
    id
    status
  }
}
```