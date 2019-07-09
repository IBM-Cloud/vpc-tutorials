import { GraphQLObjectType, GraphQLString, GraphQLList } from "graphql";

let BucketType = new GraphQLObjectType({
  name: "Bucket",

  fields: () => ({
    key: {
      type: GraphQLString,
      resolve(parentValue) {
        return parentValue.Key;
      }
    },
    modified: {
      type: GraphQLString,
      resolve(parentValue) {
        return parentValue.LastModified;
      }
    },
    size: {
      type: GraphQLString,
      resolve(parentValue) {
        return parentValue.Size;
      }
    }
  })
});

export default BucketType;
