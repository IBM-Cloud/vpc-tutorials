import {
    GraphQLObjectType,
    GraphQLList,
    GraphQLString
} from 'graphql';

import AccountType from './AccountType';
import BucketType from './BucketType';
import TransactionType from './TransactionType';
import { getItemsFromBucket } from '../../../lib/cos' ;
import os from "os";
import { v5 as uuidv5 } from 'uuid';

var hostname = os.hostname();
var networkInterfaces = os.networkInterfaces();
var ip = networkInterfaces['ens3'][0]['address'] 
var guid = "7ab36d2d-7c0e-4cf7-8e78-7067ad789dc6"

const Query = new GraphQLObjectType({
    name: 'RootQuery',

    fields: () => ({
    
      read_database: {
        type: new GraphQLList(AccountType),
        async resolve(_, args, { pool }) {
          const client = await pool.connect();
          let { rows } = await client.query('SELECT id, transactiontime, balance FROM accounts;');
          client.release();
          return rows;
        }
      },

      read_items: {
        type: new GraphQLList(BucketType),
        async resolve(_, args, { cos, bucketName }) {
          if (cos) {
            let data = await getItemsFromBucket(cos, bucketName);
            return data.Contents;
          } else {
            return [{
              key: "", modified: "", size: ""
            }]
          }
        }
      },

      read_transaction: {
        type: new GraphQLList(TransactionType),
        args: {
          hostname: {
            type: GraphQLString
          },
          ip: {
            type: GraphQLString
          }
        },
        async resolve(_, args, { databaseHost }) {
            return [{
              id: uuidv5(hostname, guid), database_server:  databaseHost, backend_server: hostname, backend_ip: ip, frontend_server: args.hostname, frontend_ip: args.ip
            }]
        }
      }

    })
});

export default Query;