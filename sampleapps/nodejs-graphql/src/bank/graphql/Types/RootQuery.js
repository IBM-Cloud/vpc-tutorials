import {
    GraphQLObjectType,
    GraphQLList
} from 'graphql';

import AccountType from './AccountType';
import BucketType from './BucketType';
import { getItemsFromBucket } from '../../../lib/cos' ;

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
      }

    })
});

export default Query;