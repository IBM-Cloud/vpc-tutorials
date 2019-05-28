import graphQLHTTP from "express-graphql";
import bank_schema from './graphql/schema';

module.exports = function (app, pool) {
  app.use('/api/bank', graphQLHTTP((req, res) => {
    return {
      context: { pool },
      schema: bank_schema,
      graphiql: true
    }
  }));
};
