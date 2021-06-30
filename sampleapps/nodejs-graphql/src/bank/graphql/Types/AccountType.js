import {
    GraphQLObjectType,
    GraphQLString,
    GraphQLID,
    GraphQLFloat
} from 'graphql';

let AccountType = new GraphQLObjectType({
    name: 'Account',

    fields: () => ({
        id: { type: GraphQLID },
        transactiontime: { type: GraphQLString },
        balance: { type: GraphQLFloat }
    })
});

export default AccountType;