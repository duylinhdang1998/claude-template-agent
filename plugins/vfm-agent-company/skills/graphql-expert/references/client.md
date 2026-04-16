# GraphQL Client (Apollo Client + React)

## Query Example

```typescript
import { useQuery, gql } from '@apollo/client';

const FEED_QUERY = gql`
  query FeedQuery($first: Int!, $after: String) {
    viewer {
      id
      username
      avatar
    }
    feed(first: $first, after: $after) {
      edges {
        cursor
        node {
          id
          image
          caption
          likes
          hasLiked
          author {
            username
            avatar
          }
          comments(first: 3) {
            edges {
              node {
                author { username }
                text
              }
            }
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

function Feed() {
  const { data, loading, fetchMore } = useQuery(FEED_QUERY, {
    variables: { first: 10 }
  });

  if (loading) return <LoadingSpinner />;

  return (
    <div>
      {data.feed.edges.map(({ node: post }) => (
        <PostCard key={post.id} post={post} />
      ))}

      {data.feed.pageInfo.hasNextPage && (
        <button onClick={() => {
          fetchMore({
            variables: {
              after: data.feed.pageInfo.endCursor
            }
          });
        }}>
          Load More
        </button>
      )}
    </div>
  );
}
```

## Mutation Example

```typescript
const LIKE_POST_MUTATION = gql`
  mutation LikePost($postId: ID!) {
    likePost(postId: $postId) {
      post {
        id
        likes
        hasLiked
      }
    }
  }
`;

function LikeButton({ postId }: { postId: string }) {
  const [likePost, { loading }] = useMutation(LIKE_POST_MUTATION, {
    variables: { postId },
    // Optimistic UI update (Meta pattern)
    optimisticResponse: {
      likePost: {
        post: {
          id: postId,
          likes: post.likes + 1,
          hasLiked: true
        }
      }
    }
  });

  return (
    <button onClick={() => likePost()} disabled={loading}>
      ❤️ Like
    </button>
  );
}
```

## Apollo Client Setup

```typescript
import { ApolloClient, InMemoryCache, HttpLink } from '@apollo/client';

const client = new ApolloClient({
  link: new HttpLink({
    uri: '/graphql',
    credentials: 'include'
  }),
  cache: new InMemoryCache({
    typePolicies: {
      Query: {
        fields: {
          feed: {
            keyArgs: false,
            merge(existing, incoming) {
              // Merge paginated results
              return {
                ...incoming,
                edges: [...(existing?.edges || []), ...incoming.edges]
              };
            }
          }
        }
      }
    }
  })
});
```
