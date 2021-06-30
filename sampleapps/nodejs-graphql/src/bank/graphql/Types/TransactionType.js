import {
    GraphQLObjectType,
    GraphQLString,
    GraphQLID
} from 'graphql';

let TransactionType = new GraphQLObjectType({
    name: 'Transaction',

    fields: () => ({
        id: { type: GraphQLID },
        database_server: { type: GraphQLString },
        backend_server: { type: GraphQLString },
        backend_ip: { type: GraphQLString },
        frontend_server: { type: GraphQLString },
        frontend_ip: { type: GraphQLString }
    })
});

export default TransactionType;