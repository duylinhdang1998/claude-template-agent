---
name: redis-expert
description: Redis in-memory data store expertise from Netflix engineers. Use when implementing caching strategies, managing user sessions, building real-time leaderboards, pub/sub messaging, rate limiting, distributed locks, or optimizing Redis data structures (strings, hashes, sets, sorted sets, streams). Triggers on Redis, caching, session store, pub/sub, rate limiting, in-memory database, or ElastiCache.
---

# Redis Expert - In-Memory Data Store Mastery

**Purpose**: Master Redis for caching, sessions, real-time features, and high-performance data storage

**Agent**: Netflix Backend Architect
**Use When**: Implementing caching, sessions, pub/sub, rate limiting, or real-time features

---

## Overview

Redis (REmote DIctionary Server) is an in-memory data structure store used as a database, cache, message broker, and streaming engine.

**Core Strengths**:
- Extremely fast (in-memory storage)
- Rich data structures (strings, hashes, lists, sets, sorted sets)
- Pub/Sub messaging
- Persistence options
- Atomic operations
- TTL (Time To Live) support

---

## Core Concepts

### 1. Basic Commands

```bash
# Strings
SET key "value"
GET key
SET counter 0
INCR counter                 # Atomic increment
INCRBY counter 5
DECR counter

# Expiration
SET session:123 "user_data" EX 3600  # Expire in 1 hour
EXPIRE key 60                         # Set TTL to 60 seconds
TTL key                               # Check remaining TTL
PERSIST key                           # Remove expiration

# Delete
DEL key
EXISTS key
```

### 2. Hashes (Objects)

```bash
# Store user object
HSET user:1 name "John" email "john@example.com" age 30
HGET user:1 name            # Get single field
HGETALL user:1              # Get all fields
HMGET user:1 name email     # Get multiple fields
HINCRBY user:1 age 1        # Increment age
HDEL user:1 age             # Delete field
```

###  3. Lists (Queues)

```bash
# Push to list
LPUSH queue:tasks "task1"   # Push left (front)
RPUSH queue:tasks "task2"   # Push right (back)

# Pop from list
LPOP queue:tasks            # Pop from front
RPOP queue:tasks            # Pop from back
BLPOP queue:tasks 0         # Blocking pop (wait forever)

# Get elements
LRANGE queue:tasks 0 -1     # Get all elements
LLEN queue:tasks            # Get length
```

### 4. Sets (Unique Values)

```bash
# Add members
SADD tags "nodejs" "redis" "database"

# Check membership
SISMEMBER tags "nodejs"     # Returns 1 if exists

# Get members
SMEMBERS tags               # Get all members
SCARD tags                  # Get count

# Set operations
SADD set1 "a" "b" "c"
SADD set2 "b" "c" "d"
SINTER set1 set2            # Intersection: ["b", "c"]
SUNION set1 set2            # Union: ["a", "b", "c", "d"]
SDIFF set1 set2             # Difference: ["a"]
```

### 5. Sorted Sets (Ranked Data)

```bash
# Add members with scores
ZADD leaderboard 100 "player1" 200 "player2" 150 "player3"

# Get by rank
ZRANGE leaderboard 0 -1 WITHSCORES           # All, lowest to highest
ZREVRANGE leaderboard 0 9 WITHSCORES         # Top 10, highest to lowest

# Get by score
ZRANGEBYSCORE leaderboard 100 200            # Score between 100-200

# Get rank
ZRANK leaderboard "player1"                  # Rank (0-indexed)
ZREVRANK leaderboard "player1"               # Reverse rank

# Increment score
ZINCRBY leaderboard 50 "player1"             # Add 50 to player1's score

# Get score
ZSCORE leaderboard "player1"
```

---

## Common Use Cases

### 1. Caching

```typescript
import Redis from 'ioredis'

const redis = new Redis(process.env.REDIS_URL)

async function getUser(id: number) {
  const cacheKey = `user:${id}`

  // Try cache first
  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }

  // Cache miss - fetch from database
  const user = await db.user.findUnique({ where: { id } })

  // Store in cache for 1 hour
  await redis.setex(cacheKey, 3600, JSON.stringify(user))

  return user
}

// Invalidate cache on update
async function updateUser(id: number, data: any) {
  await db.user.update({ where: { id }, data })

  // Clear cache
  await redis.del(`user:${id}`)
}
```

### 2. Session Storage

```typescript
import session from 'express-session'
import RedisStore from 'connect-redis'
import { createClient } from 'redis'

const redisClient = createClient({ url: process.env.REDIS_URL })
await redisClient.connect()

app.use(
  session({
    store: new RedisStore({ client: redisClient }),
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
      maxAge: 1000 * 60 * 60 * 24 * 7 // 1 week
    }
  })
)

// Use session
app.post('/login', (req, res) => {
  req.session.userId = user.id
  res.json({ success: true })
})

app.get('/profile', (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ error: 'Not authenticated' })
  }
  // ...
})
```

### 3. Rate Limiting

```typescript
async function checkRateLimit(ip: string): Promise<boolean> {
  const key = `rate_limit:${ip}`

  // Increment counter
  const requests = await redis.incr(key)

  // Set expiration on first request
  if (requests === 1) {
    await redis.expire(key, 60) // 1 minute window
  }

  // Check if limit exceeded
  const limit = 100 // 100 requests per minute
  return requests <= limit
}

// Use in middleware
app.use(async (req, res, next) => {
  const allowed = await checkRateLimit(req.ip)

  if (!allowed) {
    return res.status(429).json({ error: 'Too many requests' })
  }

  next()
})

// Sliding window rate limit (more accurate)
async function slidingWindowRateLimit(key: string, limit: number, window: number) {
  const now = Date.now()
  const windowStart = now - window * 1000

  // Remove old entries
  await redis.zremrangebyscore(key, 0, windowStart)

  // Count requests in current window
  const count = await redis.zcard(key)

  if (count >= limit) {
    return false
  }

  // Add current request
  await redis.zadd(key, now, `${now}`)
  await redis.expire(key, window)

  return true
}
```

### 4. Pub/Sub (Real-Time Messaging)

```typescript
import Redis from 'ioredis'

// Publisher
const publisher = new Redis()

// Publish message
await publisher.publish('notifications', JSON.stringify({
  userId: 123,
  message: 'You have a new message'
}))

// Subscriber
const subscriber = new Redis()

subscriber.subscribe('notifications', (err, count) => {
  console.log(`Subscribed to ${count} channel(s)`)
})

subscriber.on('message', (channel, message) => {
  console.log(`Received from ${channel}:`, message)
  const data = JSON.parse(message)

  // Handle notification (e.g., send to WebSocket clients)
  io.to(data.userId).emit('notification', data)
})

// Unsubscribe
subscriber.unsubscribe('notifications')
```

### 5. Job Queue (Bull/BullMQ)

```typescript
import { Queue, Worker } from 'bullmq'

// Create queue
const emailQueue = new Queue('emails', {
  connection: {
    host: 'localhost',
    port: 6379
  }
})

// Add job
await emailQueue.add('send-welcome', {
  email: 'user@example.com',
  name: 'John'
})

// Process jobs
const worker = new Worker('emails', async job => {
  if (job.name === 'send-welcome') {
    await sendWelcomeEmail(job.data.email, job.data.name)
  }
}, {
  connection: {
    host: 'localhost',
    port: 6379
  }
})

worker.on('completed', job => {
  console.log(`Job ${job.id} completed`)
})

worker.on('failed', (job, err) => {
  console.error(`Job ${job.id} failed:`, err)
})
```

### 6. Leaderboard

```typescript
// Add score
async function updateScore(playerId: string, score: number) {
  await redis.zadd('leaderboard', score, playerId)
}

// Get top 10
async function getTopPlayers(limit = 10) {
  const players = await redis.zrevrange('leaderboard', 0, limit - 1, 'WITHSCORES')

  // Format: [player1, score1, player2, score2, ...]
  const leaderboard = []
  for (let i = 0; i < players.length; i += 2) {
    leaderboard.push({
      playerId: players[i],
      score: parseInt(players[i + 1]),
      rank: i / 2 + 1
    })
  }

  return leaderboard
}

// Get player rank
async function getPlayerRank(playerId: string) {
  const rank = await redis.zrevrank('leaderboard', playerId)
  const score = await redis.zscore('leaderboard', playerId)

  return {
    playerId,
    rank: rank !== null ? rank + 1 : null,
    score: score ? parseInt(score) : 0
  }
}
```

---

## Best Practices

### 1. Use Connection Pooling

```typescript
import Redis from 'ioredis'

// Single instance for simple cases
export const redis = new Redis(process.env.REDIS_URL)

// Cluster for high availability
export const redis = new Redis.Cluster([
  { host: 'node1', port: 6379 },
  { host: 'node2', port: 6379 },
  { host: 'node3', port: 6379 }
])
```

### 2. Use Proper Key Naming

```bash
# Good: Hierarchical, descriptive
user:123:profile
user:123:sessions:abc
cache:product:456
queue:emails
rate_limit:api:192.168.1.1

# Bad: Unclear, no structure
u123
data
temp
```

### 3. Set Expiration on Keys

```typescript
// Always set TTL to prevent memory leak
await redis.setex('key', 3600, 'value')  // 1 hour

// Or use EXPIRE
await redis.set('key', 'value')
await redis.expire('key', 3600)

// Check for keys without TTL
// (In production, monitor this)
const keys = await redis.keys('*')
for (const key of keys) {
  const ttl = await redis.ttl(key)
  if (ttl === -1) {
    console.warn(`Key without TTL: ${key}`)
  }
}
```

### 4. Use Pipelines for Multiple Commands

```typescript
// Without pipeline (slow - multiple round trips)
await redis.set('key1', 'value1')
await redis.set('key2', 'value2')
await redis.set('key3', 'value3')

// With pipeline (fast - single round trip)
const pipeline = redis.pipeline()
pipeline.set('key1', 'value1')
pipeline.set('key2', 'value2')
pipeline.set('key3', 'value3')
await pipeline.exec()
```

### 5. Handle Connection Errors

```typescript
redis.on('error', (err) => {
  console.error('Redis error:', err)
})

redis.on('connect', () => {
  console.log('Redis connected')
})

redis.on('reconnecting', () => {
  console.log('Redis reconnecting')
})
```

---

## Monitoring

```bash
# Redis CLI
redis-cli

# Monitor all commands (debug only)
MONITOR

# Get info
INFO
INFO memory
INFO stats

# Get memory usage of key
MEMORY USAGE key

# Get all keys (NEVER use in production on large datasets)
KEYS *

# Better: Use SCAN
SCAN 0 MATCH user:* COUNT 100
```

---

## Persistence Options

```conf
# redis.conf

# RDB (snapshot) - save every 60 seconds if at least 1000 keys changed
save 60 1000

# AOF (append-only file) - log every write operation
appendonly yes
appendfsync everysec

# Use both for maximum durability
```

---

**Remember**: Redis is fast but uses memory. Set expiration on keys, use proper data structures, and monitor memory usage.

**Created**: 2026-02-04
**Maintained By**: Netflix Backend Architect
**Version**: Redis 7+
