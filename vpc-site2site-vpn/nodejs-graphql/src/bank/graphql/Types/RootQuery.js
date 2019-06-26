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
        async resolve(_, args, context) {
          const client = await context.pool.connect();
          let { rows } = await client.query('SELECT id, transactiontime, balance FROM accounts;');
          client.release();
          return rows;
        }
      },

      read_storage: {
        type: new GraphQLList(BucketType),
        async resolve(_, args, context) {
          let data = await getItemsFromBucket(context.cos, context.bucketName);
          return data.Contents;
        }
      }

    })
});

export default Query;