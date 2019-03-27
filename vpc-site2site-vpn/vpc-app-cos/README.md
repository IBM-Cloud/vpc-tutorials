# Simple app to show buckets and files from IBM Cloud Object Storage service

This sample app demonstrates how to build a very simple app and API wrapper for the IBM Cloud Object Storage service.

## Setup
The app needs a file **credentials.json** placed in its app directory. Access your COS service instance in the IBM Cloud UI, click on service credentials. Copy that JSON structure into a new file named **credentials.json**.

Another way of obtaining that JSON structure is using the IBM Cloud CLI.
1. Create a service key with role **Reader**:
   ```
   ibmcloud resource service-key-create vpns2s-cos-key Reader --instance-name vpns2s-cos
   ```
  
2. Obtain the service key details in JSON format and store it in a new file **credentials.json** in this subdirectory **vpc-app-cos**. The file will be used later on by the app.
   ```
   ibmcloud resource service-key vpns2s-cos-key --output json > credentials.json
   ```

The app is coded in Python and needs a Python runtime environment and certain modules installed.
1. Install Python and the Python package manager PIP.
   ```
   apt-get update; apt-get install python python-pip
   ```
2. Install the necessary Python packages using **pip**.
   ```
   pip install -r requirements.txt
   ```

## Start the app
   
1. Start the app:
   ```
   python browseCOS.py
   ```
2. Access the app from another terminal:
   ```
   curl localhost:8080/api/bucketlist
   ```
   The command should return a JSON object. Use address `localhost:8080/api/bucketlist` as URI if testing with a web browser.
