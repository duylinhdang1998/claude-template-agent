# GraphQL Schema Definition

Instagram-style schema with Relay cursor connections.

## Basic Types

```graphql
# schema.graphql
type User {
  id: ID!
  username: String!
  displayName: String
  avatar: String
  bio: String
  followers(first: Int, after: String): FollowersConnection!
  following(first: Int, after: String): FollowingConnection!
  posts(first: Int, after: String): PostsConnection!
  isFollowing: Boolean!
}

type Post {
  id: ID!
  author: User!
  image: String!
  caption: String
  likes: Int!
  comments(first: Int, after: String): CommentsConnection!
  createdAt: DateTime!
  hasLiked: Boolean!
}

type Comment {
  id: ID!
  author: User!
  text: String!
  createdAt: DateTime!
  likes: Int!
}
```

## Relay Cursor Connections

Meta's pattern for pagination:

```graphql
type PostsConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type PostEdge {
  cursor: String!
  node: Post!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

## Queries

```graphql
type Query {
  viewer: User
  user(username: String!): User
  post(id: ID!): Post
  feed(first: Int, after: String): PostsConnection!
}
```

## Mutations

```graphql
type Mutation {
  createPost(input: CreatePostInput!): CreatePostPayload!
  likePost(postId: ID!): LikePostPayload!
  followUser(userId: ID!): FollowUserPayload!
}

input CreatePostInput {
  image: String!
  caption: String
}

type CreatePostPayload {
  post: Post!
  user: User!
}
```

## When to Use Connections

Use Relay connections when:
- Paginating through lists
- Need hasNextPage/hasPreviousPage
- Want stable cursors
- Meta/Relay standard
