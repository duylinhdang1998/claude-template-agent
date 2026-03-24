# Real-Time Systems - Code Examples

## Table of Contents
1. [WebSocket Native](#websocket-native)
2. [Socket.IO](#socketio)
3. [Server-Sent Events](#server-sent-events)
4. [Chat Application](#chat-application)
5. [Live Notifications](#live-notifications)
6. [Live Dashboard](#live-dashboard)
7. [Collaborative Editing](#collaborative-editing)
8. [Best Practices](#best-practices)
9. [Performance Optimization](#performance-optimization)

---

## WebSocket Native

### Server (Node.js with ws)
```typescript
import { WebSocketServer } from 'ws'

const wss = new WebSocketServer({ port: 8080 })

wss.on('connection', (ws) => {
  console.log('Client connected')

  // Send message to client
  ws.send(JSON.stringify({ type: 'welcome', message: 'Connected!' }))

  // Receive message from client
  ws.on('message', (data) => {
    const message = JSON.parse(data.toString())
    console.log('Received:', message)

    // Broadcast to all clients
    wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(message))
      }
    })
  })

  ws.on('close', () => {
    console.log('Client disconnected')
  })

  ws.on('error', (error) => {
    console.error('WebSocket error:', error)
  })
})
```

### Client (Browser)
```typescript
const ws = new WebSocket('ws://localhost:8080')

ws.onopen = () => {
  console.log('Connected')
  ws.send(JSON.stringify({ type: 'message', text: 'Hello!' }))
}

ws.onmessage = (event) => {
  const data = JSON.parse(event.data)
  console.log('Received:', data)
}

ws.onclose = () => {
  console.log('Disconnected')
}

ws.onerror = (error) => {
  console.error('Error:', error)
}
```

---

## Socket.IO

### Server
```typescript
import { Server } from 'socket.io'
import { createServer } from 'http'

const httpServer = createServer()
const io = new Server(httpServer, {
  cors: {
    origin: 'http://localhost:3000',
    credentials: true
  }
})

io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`)

  // Join room
  socket.on('join-room', (roomId) => {
    socket.join(roomId)
    socket.to(roomId).emit('user-joined', socket.id)
  })

  // Send message to room
  socket.on('send-message', ({ roomId, message }) => {
    io.to(roomId).emit('receive-message', {
      senderId: socket.id,
      message,
      timestamp: Date.now()
    })
  })

  // Private message
  socket.on('private-message', ({ recipientId, message }) => {
    io.to(recipientId).emit('receive-private-message', {
      senderId: socket.id,
      message
    })
  })

  // Broadcast to all except sender
  socket.on('typing', ({ roomId }) => {
    socket.to(roomId).emit('user-typing', socket.id)
  })

  socket.on('disconnect', (reason) => {
    console.log(`User disconnected: ${socket.id}, reason: ${reason}`)
  })
})

httpServer.listen(8080)
```

### Client (React)
```typescript
import { useEffect, useState } from 'react'
import { io } from 'socket.io-client'

const socket = io('http://localhost:8080', {
  auth: {
    token: 'user-token'
  }
})

function Chat() {
  const [messages, setMessages] = useState([])

  useEffect(() => {
    // Join room
    socket.emit('join-room', 'room-123')

    // Listen for messages
    socket.on('receive-message', (data) => {
      setMessages(prev => [...prev, data])
    })

    // Listen for typing indicator
    socket.on('user-typing', (userId) => {
      console.log(`${userId} is typing...`)
    })

    // Cleanup
    return () => {
      socket.off('receive-message')
      socket.off('user-typing')
    }
  }, [])

  const sendMessage = (text: string) => {
    socket.emit('send-message', {
      roomId: 'room-123',
      message: text
    })
  }

  return (
    <div>
      {messages.map((msg, i) => (
        <div key={i}>{msg.message}</div>
      ))}
      <input onKeyPress={(e) => {
        if (e.key === 'Enter') sendMessage(e.target.value)
      }} />
    </div>
  )
}
```

---

## Server-Sent Events

### Server (One-way: Server → Client)
```typescript
import express from 'express'

const app = express()

app.get('/events', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')

  // Send event every 1 second
  const intervalId = setInterval(() => {
    const data = {
      time: new Date().toISOString(),
      value: Math.random()
    }

    res.write(`data: ${JSON.stringify(data)}\n\n`)
  }, 1000)

  // Cleanup on client disconnect
  req.on('close', () => {
    clearInterval(intervalId)
    res.end()
  })
})

app.listen(3000)
```

### Client
```typescript
const eventSource = new EventSource('http://localhost:3000/events')

eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data)
  console.log('Received:', data)
}

eventSource.onerror = (error) => {
  console.error('SSE error:', error)
  eventSource.close()
}
```

---

## Chat Application

```typescript
// Server
interface User {
  id: string
  username: string
  socketId: string
}

const users = new Map<string, User>()
const rooms = new Map<string, Set<string>>()

io.on('connection', (socket) => {
  // User authentication
  const userId = socket.handshake.auth.userId
  const username = socket.handshake.auth.username

  users.set(userId, {
    id: userId,
    username,
    socketId: socket.id
  })

  // Join room
  socket.on('join-room', (roomId) => {
    socket.join(roomId)

    if (!rooms.has(roomId)) {
      rooms.set(roomId, new Set())
    }
    rooms.get(roomId).add(userId)

    // Notify others
    socket.to(roomId).emit('user-joined', {
      userId,
      username,
      timestamp: Date.now()
    })

    // Send room users
    const roomUsers = Array.from(rooms.get(roomId)).map(id => users.get(id))
    socket.emit('room-users', roomUsers)
  })

  // Send message
  socket.on('send-message', async ({ roomId, text }) => {
    // Save to database
    const message = await db.message.create({
      data: {
        roomId,
        userId,
        text,
        createdAt: new Date()
      }
    })

    // Broadcast to room
    io.to(roomId).emit('new-message', {
      id: message.id,
      text: message.text,
      userId,
      username,
      timestamp: message.createdAt
    })
  })

  // Typing indicator
  socket.on('typing-start', ({ roomId }) => {
    socket.to(roomId).emit('user-typing', { userId, username })
  })

  socket.on('typing-stop', ({ roomId }) => {
    socket.to(roomId).emit('user-stopped-typing', { userId })
  })

  // Leave room
  socket.on('leave-room', (roomId) => {
    socket.leave(roomId)
    rooms.get(roomId)?.delete(userId)

    socket.to(roomId).emit('user-left', { userId, username })
  })

  // Disconnect
  socket.on('disconnect', () => {
    users.delete(userId)

    // Remove from all rooms
    rooms.forEach((userSet, roomId) => {
      if (userSet.has(userId)) {
        userSet.delete(userId)
        io.to(roomId).emit('user-left', { userId, username })
      }
    })
  })
})
```

---

## Live Notifications

```typescript
// Notification service with Redis Pub/Sub
import Redis from 'ioredis'

const publisher = new Redis()
const subscriber = new Redis()

// Subscribe to notifications channel
subscriber.subscribe('notifications')

subscriber.on('message', (channel, message) => {
  const notification = JSON.parse(message)

  // Send to specific user
  io.to(`user:${notification.userId}`).emit('notification', notification)
})

// When user connects, join their personal room
io.on('connection', (socket) => {
  const userId = socket.handshake.auth.userId
  socket.join(`user:${userId}`)
})

// Publish notification from anywhere in your app
async function sendNotification(userId: number, data: any) {
  await publisher.publish('notifications', JSON.stringify({
    userId,
    ...data
  }))
}

// Usage
await sendNotification(123, {
  type: 'message',
  title: 'New Message',
  body: 'You have a new message from John'
})
```

---

## Live Dashboard

```typescript
// Server: Stream analytics data
setInterval(async () => {
  const stats = await getSystemStats()

  io.to('dashboard').emit('stats-update', {
    cpu: stats.cpu,
    memory: stats.memory,
    activeUsers: stats.activeUsers,
    requestsPerSecond: stats.rps,
    timestamp: Date.now()
  })
}, 1000)

// Client: Real-time chart updates
function Dashboard() {
  const [stats, setStats] = useState([])

  useEffect(() => {
    socket.emit('join-room', 'dashboard')

    socket.on('stats-update', (data) => {
      setStats(prev => [...prev.slice(-59), data]) // Keep last 60 seconds
    })

    return () => socket.off('stats-update')
  }, [])

  return <LineChart data={stats} />
}
```

---

## Collaborative Editing

```typescript
// Server: Broadcast changes with Operational Transform
io.on('connection', (socket) => {
  socket.on('join-document', (docId) => {
    socket.join(`doc:${docId}`)

    // Send current document state
    const doc = documents.get(docId)
    socket.emit('document-state', doc)
  })

  socket.on('edit', async ({ docId, operation }) => {
    // Apply operation
    const doc = documents.get(docId)
    const transformedOp = transform(doc, operation)

    doc.apply(transformedOp)
    documents.set(docId, doc)

    // Broadcast to others
    socket.to(`doc:${docId}`).emit('remote-edit', {
      operation: transformedOp,
      userId: socket.userId
    })

    // Save to database (debounced)
    await saveDocument(docId, doc)
  })

  socket.on('cursor-move', ({ docId, position }) => {
    socket.to(`doc:${docId}`).emit('remote-cursor', {
      userId: socket.userId,
      position
    })
  })
})
```

---

## Best Practices

### Authentication & Authorization
```typescript
import jwt from 'jsonwebtoken'

io.use((socket, next) => {
  const token = socket.handshake.auth.token

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET)
    socket.userId = payload.userId
    next()
  } catch (error) {
    next(new Error('Authentication failed'))
  }
})

// Room-level authorization
socket.on('join-room', async (roomId) => {
  const hasAccess = await checkRoomAccess(socket.userId, roomId)

  if (!hasAccess) {
    socket.emit('error', { message: 'Access denied' })
    return
  }

  socket.join(roomId)
})
```

### Handle Reconnections
```typescript
// Client: Auto-reconnect with exponential backoff
const socket = io('http://localhost:8080', {
  reconnection: true,
  reconnectionDelay: 1000,
  reconnectionDelayMax: 5000,
  reconnectionAttempts: 5
})

socket.on('disconnect', (reason) => {
  console.log('Disconnected:', reason)

  if (reason === 'io server disconnect') {
    // Server kicked us, manual reconnect
    socket.connect()
  }
  // Otherwise Socket.IO will auto-reconnect
})

socket.on('connect', () => {
  console.log('Connected/Reconnected')

  // Rejoin rooms
  socket.emit('join-room', currentRoomId)
})
```

### Rate Limiting
```typescript
const rateLimitMap = new Map()

io.on('connection', (socket) => {
  socket.on('send-message', ({ roomId, text }) => {
    const key = `${socket.id}:send-message`
    const now = Date.now()

    if (!rateLimitMap.has(key)) {
      rateLimitMap.set(key, [])
    }

    const timestamps = rateLimitMap.get(key)
    const recentRequests = timestamps.filter(t => now - t < 60000) // Last minute

    if (recentRequests.length >= 10) {
      socket.emit('error', { message: 'Rate limit exceeded' })
      return
    }

    recentRequests.push(now)
    rateLimitMap.set(key, recentRequests)

    // Process message
    // ...
  })
})
```

### Horizontal Scaling (Redis Adapter)
```typescript
import { createAdapter } from '@socket.io/redis-adapter'
import { createClient } from 'redis'

const pubClient = createClient({ url: process.env.REDIS_URL })
const subClient = pubClient.duplicate()

await Promise.all([pubClient.connect(), subClient.connect()])

io.adapter(createAdapter(pubClient, subClient))

// Now you can run multiple Socket.IO servers
// Messages will be synchronized via Redis
```

---

## Performance Optimization

### Use Binary Protocol
```typescript
// Instead of JSON
socket.emit('data', { x: 100, y: 200 })

// Use binary (MessagePack, Protocol Buffers)
import msgpack from 'msgpack-lite'

const buffer = msgpack.encode({ x: 100, y: 200 })
socket.emit('data', buffer)

// Client
socket.on('data', (buffer) => {
  const data = msgpack.decode(buffer)
})
```

### Batch Updates
```typescript
// Bad: Send every update immediately
positions.forEach(pos => socket.emit('position', pos))

// Good: Batch updates
const batch = []
positions.forEach(pos => batch.push(pos))
socket.emit('positions-batch', batch)
```

### Use Rooms Efficiently
```typescript
// Bad: Loop through all sockets
io.sockets.sockets.forEach(socket => {
  if (socket.gameId === 'game-123') {
    socket.emit('update', data)
  }
})

// Good: Use rooms
io.to('game-123').emit('update', data)
```

### Monitoring
```typescript
// Track connections
io.on('connection', (socket) => {
  console.log(`Total connections: ${io.engine.clientsCount}`)

  socket.on('disconnect', () => {
    console.log(`Remaining connections: ${io.engine.clientsCount}`)
  })
})

// Memory usage
setInterval(() => {
  console.log('Rooms:', io.sockets.adapter.rooms.size)
  console.log('Memory:', process.memoryUsage())
}, 60000)
```
