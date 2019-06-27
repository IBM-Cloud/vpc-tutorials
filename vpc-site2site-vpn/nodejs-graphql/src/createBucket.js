import ibmcossdk from 'ibm-cos-sdk';

import config from "../config/config.json";
import { getEndpoints } from './lib/cos' ;
import cos_credentials from "../config/cos_credentials.json";

const credentials = cos_credentials[0].credentials;

(async function createBuckets() {

  let endpoints = await getEndpoints(`${credentials.endpoints}`);
  if (endpoints["service-endpoints"]) {
    let endpoint = endpoints["service-endpoints"][config.endpoint_type][config.region][config.type][config.location]

    let cos_config = {
      endpoint: endpoint,
      apiKeyId: credentials.apikey,
      ibmAuthEndpoint: 'https://iam.cloud.ibm.com/identity/token',
      serviceInstanceId: credentials.resource_instance_id
    };
    
    let cos = new ibmcossdk.S3(cos_config);
    let bucketName = config.bucketName;

    console.log(`Creating new bucket: ${bucketName}`);
    await cos.createBucket({
      Bucket: bucketName,
      CreateBucketConfiguration: {
        LocationConstraint: `${config.region}-${config.location_constraint}`
      }
    }).promise();
    console.log(`Bucket: ${bucketName} created!`);
    
    console.log('Retrieving list of buckets');
    let data = await cos.listBuckets().promise()

    if (data.Buckets != null) {
      for (var i = 0; i < data.Buckets.length; i++) {
        console.log(`Bucket Name: ${data.Buckets[i].Name}`);
      }
    }
  }
  process.exit(0)
}())
.catch(error => console.error(error));