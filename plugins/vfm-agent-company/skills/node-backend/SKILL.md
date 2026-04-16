---
name: node-backend
description: Node.js backend development from Netflix architects (260M+ users scale). Use when building REST APIs with Express/Fastify, implementing authentication (JWT, OAuth), designing database schemas, creating middleware, handling file uploads, building microservices in Node.js, or optimizing server performance. Triggers on Node.js backend, Express, Fastify, REST API, server-side JavaScript, middleware, or Node.js API development.
---

# Node.js Backend - Server-Side JavaScript Mastery

**Purpose**: Build scalable, high-performance backend systems with Node.js

**Agent**: Netflix Backend Architect
**Use When**: Building REST APIs, microservices, real-time servers, or any backend JavaScript application

---

## Overview

Node.js is a JavaScript runtime built on Chrome's V8 engine, designed for building scalable network applications with non-blocking I/O.

**Core Philosophy**:
- Event-driven, non-blocking I/O
- Single-threaded but highly concurrent
- JavaScript everywhere (frontend + backend)
- NPM ecosystem (largest package registry)
- Perfect for I/O-heavy applications

---

## Core Concepts

### 1. Express.js - Web Framework

```typescript
import express, { Request, Response } from 'express'

const app = express()

// Middleware
app.use(express.json())
app.use(express.urlencoded({ extended: true }))

// Routes
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok' })
})

app.post('/users', async (req: Request, res: Response) => {
  const { name, email } = req.body
  const user = await db.user.create({ data: { name, email } })
  res.status(201).json(user)
})

app.listen(3000, () => {
  console.log('Server running on port 3000')
})
```

### 2. RESTful API Design

```typescript
// User routes
app.get('/api/users', getAllUsers)           // List all
app.post('/api/users', createUser)           // Create
app.get('/api/users/:id', getUser)           // Get one
app.put('/api/users/:id', updateUser)        // Update
app.delete('/api/users/:id', deleteUser)     // Delete

// Route handlers
async function getAllUsers(req: Request, res: Response) {
  const { page = 1, limit = 10 } = req.query

  const users = await db.user.findMany({
    skip: (Number(page) - 1) * Number(limit),
    take: Number(limit)
  })

  res.json({
    data: users,
    page: Number(page),
    limit: Number(limit)
  })
}

async function createUser(req: Request, res: Response) {
  try {
    const user = await db.user.create({
      data: req.body
    })
    res.status(201).json(user)
  } catch (error) {
    res.status(400).json({ error: error.message })
  }
}
```

### 3. Middleware Pattern

```typescript
// Logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`)
  next()
})

// Authentication middleware
const authenticate = async (req: Request, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.replace('Bearer ', '')

  if (!token) {
    return res.status(401).json({ error: 'No token provided' })
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET)
    req.user = payload
    next()
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' })
  }
}

// Use middleware
app.get('/api/profile', authenticate, async (req, res) => {
  const user = await db.user.findUnique({
    where: { id: req.user.id }
  })
  res.json(user)
})

// Error handling middleware (must be last)
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({ error: 'Internal server error' })
})
```

### 4. Async/Await Error Handling

```typescript
// Wrapper for async route handlers
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next)
}

// Use wrapper
app.get('/api/users/:id', asyncHandler(async (req, res) => {
  const user = await db.user.findUniqueOrThrow({
    where: { id: parseInt(req.params.id) }
  })
  res.json(user)
}))

// Or use try-catch
app.get('/api/users/:id', async (req, res, next) => {
  try {
    const user = await db.user.findUniqueOrThrow({
      where: { id: parseInt(req.params.id) }
    })
    res.json(user)
  } catch (error) {
    next(error) // Pass to error handler
  }
})
```

### 5. Database Integration (Prisma)

```typescript
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
  createdAt DateTime @default(now())
}

// Usage
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

// CRUD operations
const users = await prisma.user.findMany({
  include: { posts: true }
})

const user = await prisma.user.create({
  data: {
    email: 'john@example.com',
    name: 'John',
    posts: {
      create: { title: 'First Post', content: 'Hello World' }
    }
  }
})

const updatedUser = await prisma.user.update({
  where: { id: 1 },
  data: { name: 'John Doe' }
})

await prisma.user.delete({ where: { id: 1 } })
```

---

## Best Practices

### 1. Environment Variables

```typescript
// .env
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
JWT_SECRET=your-secret-key
PORT=3000
NODE_ENV=development

// Load with dotenv
import dotenv from 'dotenv'
dotenv.config()

// Use environment variables
const port = process.env.PORT || 3000
const dbUrl = process.env.DATABASE_URL

// Type-safe env validation (with zod)
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string(),
  JWT_SECRET: z.string(),
  PORT: z.string().transform(Number),
  NODE_ENV: z.enum(['development', 'production', 'test'])
})

const env = envSchema.parse(process.env)
```

### 2. Structured Logging

```typescript
import pino from 'pino'

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty',
    options: { colorize: true }
  }
})

// Use logger
logger.info({ userId: 123 }, 'User logged in')
logger.error({ error: err }, 'Failed to process request')

// Express middleware
app.use((req, res, next) => {
  req.log = logger.child({ requestId: crypto.randomUUID() })
  req.log.info({ method: req.method, url: req.url }, 'Incoming request')
  next()
})
```

### 3. Validation (Zod)

```typescript
import { z } from 'zod'

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2).max(50),
  age: z.number().int().positive().optional()
})

app.post('/api/users', async (req, res) => {
  try {
    const data = createUserSchema.parse(req.body)
    const user = await db.user.create({ data })
    res.status(201).json(user)
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Validation failed',
        details: error.errors
      })
    }
    throw error
  }
})
```

### 4. Authentication with JWT

```typescript
import jwt from 'jsonwebtoken'
import bcrypt from 'bcrypt'

// Register
app.post('/auth/register', async (req, res) => {
  const { email, password } = req.body

  const hashedPassword = await bcrypt.hash(password, 10)

  const user = await db.user.create({
    data: {
      email,
      password: hashedPassword
    }
  })

  const token = jwt.sign(
    { userId: user.id },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  )

  res.status(201).json({ token, user })
})

// Login
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body

  const user = await db.user.findUnique({ where: { email } })

  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  const validPassword = await bcrypt.compare(password, user.password)

  if (!validPassword) {
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  const token = jwt.sign(
    { userId: user.id },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  )

  res.json({ token, user })
})
```

### 5. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit'

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
})

// Apply to all routes
app.use(limiter)

// Or specific routes
app.use('/api/auth/login', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5 // Only 5 login attempts per 15 minutes
}))
```

---

## Common Patterns

### Repository Pattern

```typescript
// repositories/userRepository.ts
class UserRepository {
  async findById(id: number) {
    return await prisma.user.findUnique({ where: { id } })
  }

  async findByEmail(email: string) {
    return await prisma.user.findUnique({ where: { email } })
  }

  async create(data: CreateUserDto) {
    return await prisma.user.create({ data })
  }

  async update(id: number, data: UpdateUserDto) {
    return await prisma.user.update({ where: { id }, data })
  }

  async delete(id: number) {
    return await prisma.user.delete({ where: { id } })
  }
}

export const userRepository = new UserRepository()

// Use in routes
app.get('/api/users/:id', async (req, res) => {
  const user = await userRepository.findById(parseInt(req.params.id))
  if (!user) {
    return res.status(404).json({ error: 'User not found' })
  }
  res.json(user)
})
```

### Service Layer

```typescript
// services/userService.ts
class UserService {
  async createUser(data: CreateUserDto) {
    // Business logic
    const existingUser = await userRepository.findByEmail(data.email)
    if (existingUser) {
      throw new Error('User already exists')
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(data.password, 10)

    // Create user
    return await userRepository.create({
      ...data,
      password: hashedPassword
    })
  }

  async getUserProfile(userId: number) {
    const user = await userRepository.findById(userId)
    if (!user) {
      throw new Error('User not found')
    }

    // Don't return password
    const { password, ...profile } = user
    return profile
  }
}

export const userService = new UserService()

// Use in routes
app.post('/api/users', async (req, res) => {
  try {
    const user = await userService.createUser(req.body)
    res.status(201).json(user)
  } catch (error) {
    res.status(400).json({ error: error.message })
  }
})
```

---

## Performance Optimization

### 1. Database Query Optimization

```typescript
// ❌ Bad: N+1 query problem
const users = await prisma.user.findMany()
for (const user of users) {
  user.posts = await prisma.post.findMany({
    where: { authorId: user.id }
  })
}

// ✅ Good: Use include/select
const users = await prisma.user.findMany({
  include: { posts: true }
})
```

### 2. Caching with Redis

```typescript
import Redis from 'ioredis'

const redis = new Redis(process.env.REDIS_URL)

app.get('/api/users/:id', async (req, res) => {
  const { id } = req.params

  // Check cache
  const cached = await redis.get(`user:${id}`)
  if (cached) {
    return res.json(JSON.parse(cached))
  }

  // Fetch from database
  const user = await prisma.user.findUnique({
    where: { id: parseInt(id) }
  })

  // Cache for 1 hour
  await redis.setex(`user:${id}`, 3600, JSON.stringify(user))

  res.json(user)
})
```

### 3. Compression

```typescript
import compression from 'compression'

app.use(compression())
```

---

## Testing

```typescript
import request from 'supertest'
import { app } from './app'

describe('User API', () => {
  it('should create a user', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({
        email: 'test@example.com',
        name: 'Test User'
      })
      .expect(201)

    expect(response.body).toHaveProperty('id')
    expect(response.body.email).toBe('test@example.com')
  })

  it('should return 401 for protected route', async () => {
    await request(app)
      .get('/api/profile')
      .expect(401)
  })
})
```

---

**Remember**: Node.js excels at I/O-heavy tasks. Use async/await, structure your code with layers (routes → services → repositories), and optimize database queries.

**Created**: 2026-02-04
**Maintained By**: Netflix Backend Architect
**Version**: Node.js 20+
