import {
  GraphQLObjectType,
  GraphQLString,
  GraphQLNonNull
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
          type: new GraphQLNonNull(GraphQLString),
          description: "balance to add"
        },
        fileText: {
          type: new GraphQLNonNull(GraphQLString),
          description: "content to add to file"
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
              Body: args.fileText
          }).promise();
        }
        let result = { id: `${rows[0].id}`, status: `Added one record in database and one item to storage bucket.`  }
        return result;
      }
    }
  })
});

export default Mutation;
