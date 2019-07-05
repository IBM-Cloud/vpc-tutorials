import ibmcossdk from 'ibm-cos-sdk';
import chalk from "chalk";
import uuidv5 from 'uuid/v5';

import config from "../config/config.json";
import { getEndpoints } from './lib/cos' ;
import cos_credentials from "../config/cos_credentials.json";

const { guid, credentials: { endpoints, apikey, resource_instance_id } } = cos_credentials[0];
const { cloud_object_storage: { bucketName, endpoint_type, region, type, location, location_constraint } } = config;

(async function createBuckets() {

  let endpoints_list = await getEndpoints(`${endpoints}`, type);
  if (endpoints_list["service-endpoints"]) {
    let endpoint = endpoints_list["service-endpoints"][endpoint_type][region][type][location]

    let cos_config = {
      endpoint: endpoint,
      apiKeyId: apikey,
      ibmAuthEndpoint: 'https://iam.cloud.ibm.com/identity/token',
      serviceInstanceId: resource_instance_id
    };
    
    let cos = new ibmcossdk.S3(cos_config);

    console.log(`Creating new bucket: ${bucketName}-${uuidv5(bucketName, guid)}`);
    await cos.createBucket({
      Bucket: `${bucketName}-${uuidv5(bucketName, guid)}`,
      CreateBucketConfiguration: {
        LocationConstraint: `${region}-${location_constraint}`
      }
    }).promise();

    console.log(
      `${chalk.green(`Bucket: ${bucketName}-${uuidv5(bucketName, guid)} created!`)}`
    );
    
    console.log('Retrieving list of buckets');
    let data = await cos.listBuckets().promise()

    if (data.Buckets != null) {
      for (var i = 0; i < data.Buckets.length; i++) {
        console.log(`Bucket Name: ${chalk.yellow(`${data.Buckets[i].Name}`)}`);
      }
    }
  }
  process.exit(0)
}())
.catch(error => console.error(error));