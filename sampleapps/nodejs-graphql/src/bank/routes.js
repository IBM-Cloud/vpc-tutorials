import { graphqlHTTP } from "express-graphql";
import bank_schema from './graphql/schema';

module.exports = function (app, pool, cos, bucketName, databaseHost) {
  app.use('/api/bank', graphqlHTTP((req, res) => {
    return {
      context: { pool, cos, bucketName, databaseHost },
      schema: bank_schema,
      graphiql: true
    }
  }));
};
