import {
  GraphQLObjectType,
  GraphQLString,
  GraphQLNonNull,
  GraphQLFloat
} from "graphql";

import { hostname } from "os";

const Mutation = new GraphQLObjectType({
  name: "RootMutation",
  description: "Mutation interface",
  fields: () => ({
    add: {
      type: new GraphQLObjectType({
        name: 'Add',
    
        fields: () => ({
          id: { type: GraphQLString },
          status: { type: GraphQLString }
        })
      }),
      args: {
        balance: {
          type: new GraphQLNonNull(GraphQLFloat),
          description: "balance to add to the account."
        },
        item_content: {
          type: GraphQLString,
          description: "content to add to an item/file that is added to the storage bucket."
        }
      },
      async resolve (_, args, { pool, cos, bucketName }) {
        
        const client = await pool.connect();
        let { rows } = await client.query(`INSERT INTO accounts (balance) VALUES (${args.balance}) RETURNING id;`);
        client.release();

        let result;

        if (cos) {
          if (rows[0].id) {
            let object = rows[0].id;
            await cos.putObject({
                Bucket: bucketName, 
                Key: `${object.replace(/-/g, "")}.txt`, 
                Body: `${args.item_content}\nThis line is added by ${hostname} at ${Date.now()}.`
            }).promise();
            
            result = { id: `${rows[0].id}`, status: `Added one record in database and one item to storage bucket.` }
          }
        } else {
          result = { id: `${rows[0].id}`, status: `Added one record in database.` }
        }

        return result;
      }
    }
  })
});

export default Mutation;
