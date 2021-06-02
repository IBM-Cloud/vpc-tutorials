import {
    GraphQLObjectType,
    GraphQLList
} from 'graphql';

import AccountType from './AccountType';
import BucketType from './BucketType';
import { getItemsFromBucket } from '../../../lib/cos' ;
import os from "os";
import uuidv5 from 'uuid/v5';

var hostname = os.hostname();
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
          }
        },
        async resolve(_, args, { }) {
            return [{
              id: uuidv5(hostname, guid), backend_server: hostname, frontend_server: args.hostname
            }]
        }
      }

    })
});

export default Query;