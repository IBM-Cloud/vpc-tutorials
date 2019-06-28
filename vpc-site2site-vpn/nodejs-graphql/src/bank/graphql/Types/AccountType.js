import {
    GraphQLObjectType,
    GraphQLString,
    GraphQLID,
    GraphQLFloat
} from 'graphql';

let NameType = new GraphQLObjectType({
  name: 'Name',

  fields: () => ({
    email: { 
      type: GraphQLString,
      resolve(parentValue) {
        return parentValue.email;
      }
    },
    displayName: { 
      type: GraphQLString,
      resolve(parentValue) {
        return parentValue.displayName;
      }
    },
  })
});

let AccountType = new GraphQLObjectType({
    name: 'Account',

    fields: () => ({
        id: { type: GraphQLID },
        transactiontime: { type: GraphQLString },
        balance: { type: GraphQLFloat },
        owner: {
          type: NameType,
          resolve(parentValue) {
            return parentValue.owner
          }
        }
    })
});

export default AccountType;