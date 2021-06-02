import {
    GraphQLObjectType,
    GraphQLString,
    GraphQLID,
    GraphQLFloat
} from 'graphql';

let TransactionType = new GraphQLObjectType({
    name: 'Transaction',

    fields: () => ({
        id: { type: GraphQLID },
        backend_server: { type: GraphQLString },
        frontend_server: { type: GraphQLString }
    })
});

export default TransactionType;