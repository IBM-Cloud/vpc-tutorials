#
# Access IBM Cloud Object Storage (COS) and return bucket and file information
# either as HTML page or in JSON format (API)
#
# Written by Henrik Loeser (data-henrik), hloeser@de.ibm.com
# (C) 2019 by IBM


import flask, os, json, datetime, requests
from flask import Flask, jsonify,redirect,request,render_template, url_for, Response
import ibm_boto3
import json
from ibm_botocore.client import Config

with open('./credentials.json') as data_file:
    credentials = json.load(data_file)

# Initialize Flask app
app = Flask(__name__)


# Rquest detailed enpoint list
endpoints = requests.get(credentials.get('endpoints')).json()
#print(endpoints['service-endpoints']['cross-region'])
# Obtain iam and cos host from the the detailed endpoints
iam_host = (endpoints['identity-endpoints']['iam-token'])
cos_host = (endpoints['service-endpoints']['cross-region']['us']['public']['Dallas'])
#cos_host = (endpoints['service-endpoints']['cross-region']['us']['public']['us-geo'])
#cos_host = (endpoints['service-endpoints']['regional']['us-south']['public']['us-south'])
#cos_host = "s3.us.cloud-object-storage.appdomain.cloud"

api_key = credentials.get('apikey')
service_instance_id = credentials.get('resource_instance_id')

# Construct auth and cos endpoint
auth_endpoint = "https://" + iam_host + "/oidc/token"
service_endpoint = "https://" + cos_host

# Create new S3 client
cos = ibm_boto3.client('s3',
                    ibm_api_key_id=api_key,
                    ibm_service_instance_id=service_instance_id,
                    ibm_auth_endpoint=auth_endpoint,
                    config=Config(signature_version='oauth'),
                    endpoint_url=service_endpoint)


def locations(buckets):
   locs={}
   for b in buckets:
      try: 
         locs[b]=cos.get_bucket_location(Bucket=b)['LocationConstraint']
      except: 
         locs[b]=None
         pass
   return locs


# Index page, unprotected to display some general information
@app.route('/', methods=['GET'])
def index():
   # Get a list of all bucket names from the response
   buckets = [bucket['Name'] for bucket in cos.list_buckets()['Buckets']]
   locs=locations(buckets=buckets)
   return render_template("index.html", buckets=locs, view="bucket")
    

@app.route('/bucket/<bucketname>', methods=['GET'])
def bucket(bucketname):
   response=cos.list_objects(Bucket=bucketname)
   objects = [{"name":fileobject['Key'],"size":fileobject['Size'],"modified":fileobject['LastModified'].isoformat()} for fileobject in response.get('Contents', [])]
   return render_template("index.html", objects=objects, bucketname=bucketname, view="object")

@app.route('/api/filelist/<bucketname>', methods=['GET'])
def filelist_json(bucketname):
   response=cos.list_objects(Bucket=bucketname)
   objects = [{"name":fileobject['Key'],"size":fileobject['Size'],"modified":fileobject['LastModified'].isoformat()} for fileobject in response.get('Contents', [])]
   return jsonify(message="only a test",objects=objects)

@app.route('/api/bucketlist', methods=['GET'])
def buckets_json():
   # Get a list of all bucket names from the response
   buckets = [bucket['Name'] for bucket in cos.list_buckets()['Buckets']]
   #locs=locations(buckets=buckets)
   locs2=[{"name":name,"loc":loc} for name,loc in locations(buckets=buckets).iteritems()]
   return jsonify(buckets=locs2)



port = os.getenv('PORT', '5000')
if __name__ == "__main__":
        app.run(host='0.0.0.0', port=int(port))
