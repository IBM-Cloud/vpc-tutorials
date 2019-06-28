import {
  GraphQLObjectType,
  GraphQLString,
  GraphQLNonNull,
  GraphQLFloat
} from "graphql";

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
      async resolve (_, args, context) {
        const client = await context.pool.connect();
        let { rows } = await client.query(`INSERT INTO accounts (balance) VALUES (${args.balance}) RETURNING id;`);
        client.release();

        if (rows[0].id) {
          await context.cos.putObject({
              Bucket: context.bucketName, 
              Key: `${rows[0].id}.txt`, 
              Body: args.item_content
          }).promise();
        }
        let result = { id: `${rows[0].id}`, status: `Added one record in database and one item to storage bucket.`  }
        return result;
      }
    }
  })
});

export default Mutation;
