import {
    GraphQLSchema,
} from 'graphql';

import Query from './Types/RootQuery';
import Mutation from './Types/RootMutation';

let schema = new GraphQLSchema({
    query: Query,
    mutation: Mutation
});

export default schema;