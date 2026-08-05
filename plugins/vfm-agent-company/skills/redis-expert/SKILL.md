---
name: redis-expert
description: Redis in-memory data store expertise from Netflix engineers. Use when implementing caching strategies, managing user sessions, building real-time leaderboards, pub/sub messaging, rate limiting, distributed locks, durable job/event streams, or optimizing Redis data structures (strings, hashes, sets, sorted sets, streams). Covers cache patterns, stampede protection, atomicity (Lua/MULTI), eviction, clustering, persistence, and production pitfalls. Triggers on Redis, caching, session store, pub/sub, rate limiting, distributed lock, Redis Streams, in-memory database, or ElastiCache.
---

# Redis Expert — In-Memory Data Store Mastery

**Agent**: Netflix Backend Architect (James Wilson) · **Stack**: Node.js + TypeScript (`ioredis`) · **Target**: Redis 7+

Redis is single-threaded for command execution (each command is atomic), in-memory,
and microsecond-fast. Treat it as a **tool with a specific shape**, not a general DB.
This skill is decision-first: pick the right structure and pattern, then the code is easy.

---

## 0. Decision framework — is Redis even the right tool?

| Need | Use Redis? | Structure / pattern |
|---|---|---|
| Cache DB reads | ✅ | String (JSON) or Hash, cache-aside + TTL |
| Session store | ✅ | Hash or String, TTL = session length |
| Rate limiting | ✅ | String INCR (fixed window) or Sorted Set (sliding) |
| Leaderboard / ranking | ✅ | Sorted Set (ZADD/ZRANGE) |
| Ephemeral pub/sub (fire-and-forget) | ✅ | Pub/Sub |
| **Durable** event queue / replay | ✅ | **Streams** (consumer groups) — NOT Pub/Sub |
| Distributed lock | ⚠️ | `SET NX PX` — read the correctness caveats below |
| Primary source of truth | ❌ | Use Postgres; Redis is a cache/derived store |
| Complex queries / joins / reporting | ❌ | Use Postgres |
| Large blobs (>100KB values) | ❌ | Object storage (S3) + cache the URL |

**Rule of thumb**: Redis holds *derived, ephemeral, or hot* data. If losing it would
cause data loss (not just a slow rebuild), it's in the wrong store.

---

## 1. Data structures → pick by access pattern

| Structure | O(?) highlights | Use for |
|---|---|---|
| String | GET/SET O(1), INCR atomic | cache JSON, counters, flags |
| Hash | HGET/HSET O(1) per field | objects you update field-by-field (avoid re-serializing) |
| List | LPUSH/RPUSH O(1), LRANGE O(n) | simple FIFO/LIFO, recent-N feeds |
| Set | SADD/SISMEMBER O(1) | membership, tags, unique visitors |
| Sorted Set | ZADD O(log n), ZRANGE O(log n + m) | leaderboards, sliding windows, priority queues, time-series index |
| Stream | XADD O(1), consumer groups | **durable** logs/queues with replay + ack |
| Bitmap / HyperLogLog | O(1) | daily-active flags / approximate unique counts at tiny memory |

**Hash vs String(JSON)**: use a Hash when you update individual fields often (no
read-modify-write of the whole object). Use a JSON String when you always read/write
the whole object and want it atomic in one key.

---

## 2. Caching — patterns and the traps that bite in production

### Cache-aside (lazy loading) — the default
```typescript
import Redis from 'ioredis'
const redis = new Redis(process.env.REDIS_URL!)

async function getUser(id: number): Promise<User> {
  const key = `user:${id}`
  const cached = await redis.get(key)
  if (cached) return JSON.parse(cached)

  const user = await db.user.findUniqueOrThrow({ where: { id } })
  // SET with TTL + jitter (see stampede below). NX avoids clobbering a fresher write.
  await redis.set(key, JSON.stringify(user), 'EX', ttlWithJitter(3600))
  return user
}
```

### Invalidation — the hard part
- **Write-through the cache on update, or delete the key.** Prefer **delete** (simpler,
  avoids caching a half-built object): `await redis.del(`user:${id}`)` after the DB write.
- Delete **after** the DB commit, not before — deleting first opens a race where a
  concurrent read repopulates stale data.
- Never trust a cache you can't invalidate. If invalidation is impossible, use a short TTL.

### Cache stampede / thundering herd (the classic outage)
When a hot key expires, thousands of requests miss at once and hammer the DB.
Three defenses, use together:

1. **TTL jitter** — spread expiries so keys don't die in lockstep:
   ```typescript
   const ttlWithJitter = (base: number) => base + Math.floor(Math.random() * base * 0.1)
   ```
2. **Single-flight lock** — only one caller rebuilds; others wait or serve stale:
   ```typescript
   async function getWithLock(key: string, rebuild: () => Promise<string>, ttl: number) {
     const hit = await redis.get(key)
     if (hit) return hit
     const lockKey = `lock:${key}`
     const gotLock = await redis.set(lockKey, '1', 'NX', 'PX', 5000)
     if (!gotLock) {                       // someone else is rebuilding
       await sleep(50)
       return getWithLock(key, rebuild, ttl)   // retry (add a bounded attempt count)
     }
     try {
       const fresh = await rebuild()
       await redis.set(key, fresh, 'EX', ttlWithJitter(ttl))
       return fresh
     } finally {
       await redis.del(lockKey)
     }
   }
   ```
3. **Serve-stale-while-revalidate** — store `{value, softExpireAt}`; past soft-expire,
   return the stale value immediately and refresh in the background.

---

## 3. Atomicity — MULTI, WATCH, and Lua

Individual commands are atomic. **Multi-step** logic (read-then-write) is NOT — you need
a transaction or a script.

- **Pipeline** = batching for fewer round-trips (NOT atomic, NOT isolated):
  ```typescript
  await redis.pipeline().set('a', 1).incr('b').get('c').exec()
  ```
- **MULTI/EXEC** = queued commands run atomically. Use **WATCH** for optimistic locking
  (aborts if the watched key changed).
- **Lua script (EVAL)** = atomic read-modify-write in one round trip. Preferred for
  correctness-critical ops (rate limits, conditional decrements, atomic dequeue):
  ```typescript
  // Atomic "decrement stock if available" — no race between check and write
  const buy = `
    local n = tonumber(redis.call('GET', KEYS[1]) or '0')
    if n <= 0 then return -1 end
    return redis.call('DECR', KEYS[1])`
  const left = await redis.eval(buy, 1, `stock:${sku}`)   // -1 = sold out
  ```

---

## 4. Rate limiting

**Fixed window (cheap, bursty at boundaries):**
```typescript
async function fixedWindow(id: string, limit = 100, windowSec = 60) {
  const key = `rl:${id}:${Math.floor(Date.now() / 1000 / windowSec)}`
  const n = await redis.incr(key)
  if (n === 1) await redis.expire(key, windowSec)
  return n <= limit
}
```
**Sliding window (accurate, more memory)** — Sorted Set of timestamps, atomic via Lua in
production to avoid the check-then-act race. Keep the zset trimmed with `ZREMRANGEBYSCORE`.

For serious use, prefer a vetted lib (`rate-limiter-flexible`) — it ships the Lua and edge cases.

---

## 5. Pub/Sub vs Streams — don't confuse them

| | Pub/Sub | Streams (XADD + consumer groups) |
|---|---|---|
| Delivery | fire-and-forget; offline subscribers miss messages | durable; replay from any offset |
| Ack / retry | none | per-message ACK, pending list, auto-claim |
| Fan-out | all subscribers | consumer groups load-balance |
| Use for | live notifications, cache-invalidation signals, presence | job queues, event sourcing, at-least-once pipelines |

**Pub/Sub** for "notify anyone who's listening right now" (and to sync WebSocket servers —
see [[real-time-systems]]). **Streams** when a missed message is a bug.

```typescript
// Stream producer
await redis.xadd('events', '*', 'type', 'order.paid', 'orderId', String(id))
// Consumer group (durable, load-balanced, ack'd)
await redis.xgroup('CREATE', 'events', 'workers', '$', 'MKSTREAM').catch(() => {})
const res = await redis.xreadgroup('GROUP', 'workers', 'c1', 'COUNT', 10, 'BLOCK', 5000, 'STREAMS', 'events', '>')
// ... process ... then: await redis.xack('events', 'workers', id)
```
For app-level job queues on top of this, **BullMQ** is the batteries-included choice.

---

## 6. Distributed locks — correctness warning

`SET lock NX PX 30000` gives a simple lock, BUT it is **not safe** as the sole guard for
correctness across failures (clock skew, GC pause, lock expiring mid-work). Rules:

- Always set a TTL (`PX`) so a crashed holder can't deadlock forever.
- Release only if you own it — check-and-del must be atomic (Lua comparing a random token):
  ```typescript
  const token = crypto.randomUUID()
  await redis.set(lockKey, token, 'NX', 'PX', 30000)
  // release:
  const rel = `if redis.call('GET',KEYS[1])==ARGV[1] then return redis.call('DEL',KEYS[1]) else return 0 end`
  await redis.eval(rel, 1, lockKey, token)
  ```
- For **mutual exclusion / performance** (avoid double work): this is fine.
- For **correctness** (money, inventory) where double-execution is unacceptable: do NOT
  rely on the lock alone — make the protected operation idempotent or transactional in
  Postgres. Redlock across N nodes reduces risk but is debated; don't assume it's bulletproof.

---

## 7. Memory, eviction, persistence, clustering

- **Always set TTLs.** A key without a TTL lives forever → slow memory leak. Audit with
  `redis-cli --scan` + `TTL`. Never run `KEYS *` in prod (blocks the server) — use `SCAN`.
- **Eviction policy** (`maxmemory-policy`): for a pure cache use `allkeys-lru` (or
  `allkeys-lfu`); for a mixed store use `volatile-lru` so only TTL'd keys get evicted.
- **Big keys / hot keys** kill you: a single 50MB list or a key taking 90% of traffic
  creates latency spikes and uneven cluster shards. Split them; monitor with `redis-cli --bigkeys`.
- **Persistence**: RDB = periodic snapshot (fast restart, can lose seconds); AOF
  (`appendfsync everysec`) = durable to ~1s. Cache-only? You can disable both. Source of
  truth? Use AOF + replication — but really, don't make Redis your source of truth.
- **HA**: single node = SPOF. Use Sentinel (failover) or Cluster (sharding). In Cluster,
  multi-key ops must share a hash slot — use `{tag}` hash-tags: `user:{123}:profile`.

---

## 8. Connection & client hygiene (ioredis)

```typescript
export const redis = new Redis(process.env.REDIS_URL!, {
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  retryStrategy: (times) => Math.min(times * 200, 2000),
})
redis.on('error', (e) => logger.error({ err: e }, 'redis error'))  // never crash on transient errors
```
- **Reuse one client** (or a small pool) per process — don't create a client per request.
- **Pub/Sub needs its own connections**: a subscriber connection can't run normal commands.
  Use separate `pub` and `sub` instances.
- Set timeouts; a hung Redis call must not hang the request — wrap hot paths with a
  fallback to the DB (cache is an optimization, not a dependency for correctness).

---

## 9. Key naming & pitfalls

```
✅ user:123:profile   session:abc   cache:product:456   rl:api:1.2.3.4   {order:99}:items
❌ u123   data   temp   (no namespace, no structure)
```

**Top production pitfalls**
- ❌ `KEYS *` in prod → use `SCAN`.
- ❌ Keys with no TTL → memory creep.
- ❌ Caching without an invalidation story → stale data forever.
- ❌ Read-then-write without Lua/WATCH → lost updates under concurrency.
- ❌ Pub/Sub where you needed durability → silent message loss (use Streams).
- ❌ Treating a `SET NX` lock as a correctness guarantee → double execution.
- ❌ One giant key / hot key → latency spikes, unbalanced cluster.
- ❌ Cache in the request-critical path with no DB fallback → Redis down = app down.

---

## 10. Quick self-check before shipping Redis code

1. Does every key have a TTL (or a deliberate reason not to)?
2. Is there a clear invalidation path for every cache?
3. Are multi-step mutations atomic (Lua/MULTI), not check-then-act?
4. Is the right primitive chosen (Streams vs Pub/Sub; Sorted Set vs List)?
5. Does the app still work (slower) if Redis is briefly down?
6. No `KEYS`, no unbounded lists, no giant values?
7. Separate connections for Pub/Sub; single shared client elsewhere?

Related: [[real-time-systems]] (Redis adapter for scaling WebSockets), [[node-backend]],
[[postgresql]], [[microservices]].
