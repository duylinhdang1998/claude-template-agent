# GraphQL Optimization (DataLoader)

Meta created DataLoader to solve the N+1 query problem.

## The N+1 Problem

**Without DataLoader:**
```
Query 10 posts → 1 query
Get author for each post → 10 queries
Total: 11 queries!
```

**With DataLoader:**
```
Query 10 posts → 1 query
Get all 10 authors in one batch → 1 query
Total: 2 queries!
```

## DataLoader Implementation

```typescript
import DataLoader from 'dataloader';

function createUserLoader() {
  return new DataLoader<string, User>(async (userIds) => {
    // Batch load all users in one query
    const users = await db.users.find({
      id: { $in: userIds }
    });

    // Return in same order as requested
    const userMap = new Map(users.map(u => [u.id, u]));
    return userIds.map(id => userMap.get(id)!);
  });
}

function createPostLoader() {
  return new DataLoader<string, Post>(async (postIds) => {
    const posts = await db.posts.find({
      id: { $in: postIds }
    });

    const postMap = new Map(posts.map(p => [p.id, p]));
    return postIds.map(id => postMap.get(id)!);
  });
}
```

## Usage in Context

```typescript
// Create loaders per-request
const context = {
  userId: req.userId,
  loaders: {
    user: createUserLoader(),
    post: createPostLoader()
  }
};

// All user.load() calls in a single request are batched!
```

## How It Works

1. During a single GraphQL query, multiple resolvers call `loader.load(id)`
2. DataLoader collects all IDs
3. At the end of the event loop tick, DataLoader calls the batch function once with all IDs
4. Results are returned to each resolver

## Best Practices

- Create new loaders per-request (not singleton)
- Always return results in the same order as input IDs
- Use Map for O(1) lookup when mapping results
- Cache within a single request, not across requests
