# GraphQL Resolvers

Meta-style resolvers with DataLoader.

## Context Setup

```typescript
import DataLoader from 'dataloader';

interface Context {
  userId?: string;
  loaders: {
    user: DataLoader<string, User>;
    post: DataLoader<string, Post>;
  };
}
```

## Query Resolvers

```typescript
const resolvers = {
  Query: {
    viewer: async (_: any, __: any, context: Context) => {
      if (!context.userId) return null;
      return context.loaders.user.load(context.userId);
    },

    user: async (_: any, { username }: { username: string }, context: Context) => {
      const user = await db.users.findOne({ username });
      return user;
    },

    feed: async (_: any, { first = 10, after }: any, context: Context) => {
      if (!context.userId) throw new Error('Authentication required');

      const posts = await db.posts.find({
        authorId: { $in: await getFollowingIds(context.userId) }
      })
      .sort({ createdAt: -1 })
      .limit(first + 1);

      // Relay cursor pagination
      const hasNextPage = posts.length > first;
      const edges = posts.slice(0, first).map(post => ({
        cursor: encodeCursor(post.id),
        node: post
      }));

      return {
        edges,
        pageInfo: {
          hasNextPage,
          endCursor: edges[edges.length - 1]?.cursor
        }
      };
    }
  }
};
```

## Mutation Resolvers

```typescript
const resolvers = {
  Mutation: {
    createPost: async (_: any, { input }: any, context: Context) => {
      if (!context.userId) throw new Error('Authentication required');

      const post = await db.posts.create({
        authorId: context.userId,
        image: input.image,
        caption: input.caption,
        createdAt: new Date()
      });

      const user = await context.loaders.user.load(context.userId);

      return { post, user };
    },

    likePost: async (_: any, { postId }: { postId: string }, context: Context) => {
      if (!context.userId) throw new Error('Authentication required');

      await db.likes.create({
        userId: context.userId,
        postId,
        createdAt: new Date()
      });

      await db.posts.updateOne(
        { id: postId },
        { $inc: { likes: 1 } }
      );

      const post = await context.loaders.post.load(postId);
      return { post, success: true };
    }
  }
};
```

## Field Resolvers

```typescript
const resolvers = {
  User: {
    // Fetch related data
    followers: async (user: User, { first, after }: any, context: Context) => {
      const followers = await db.follows.find({
        followingId: user.id,
        ...(after && { id: { $gt: decodeCursor(after) } })
      }).limit(first + 1);

      // Load users via DataLoader (batched!)
      const userIds = followers.map(f => f.followerId);
      const users = await context.loaders.user.loadMany(userIds);

      return buildConnection(users, first);
    },

    isFollowing: async (user: User, _: any, context: Context) => {
      if (!context.userId) return false;

      const follow = await db.follows.findOne({
        followerId: context.userId,
        followingId: user.id
      });

      return !!follow;
    }
  },

  Post: {
    author: async (post: Post, _: any, context: Context) => {
      // DataLoader batches requests automatically
      return context.loaders.user.load(post.authorId);
    },

    hasLiked: async (post: Post, _: any, context: Context) => {
      if (!context.userId) return false;

      const like = await db.likes.findOne({
        userId: context.userId,
        postId: post.id
      });

      return !!like;
    }
  }
};
```
