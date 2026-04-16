---
name: security-expert
description: Application security expertise covering OWASP Top 10 prevention. Use when implementing authentication (JWT, OAuth2, OIDC), authorization (RBAC, ABAC), encryption (AES, RSA, TLS), securing APIs, preventing XSS/CSRF/SQL injection, conducting security audits, managing secrets, or hardening production systems. Triggers on security, authentication, authorization, encryption, OWASP, vulnerability, XSS, CSRF, or security best practices.
---
# Security Expert - Application Security & Best Practices

**Purpose**: Implement secure authentication, authorization, encryption, and protection against common vulnerabilities (OWASP Top 10)

**Agent**: Google Blockchain Security / Amazon Cloud Architect
**Use When**: Building authentication, handling sensitive data, securing APIs, or conducting security audits

---

## Overview

Application security protects against unauthorized access, data breaches, and malicious attacks.

**Core Principles**:
- **Defense in Depth**: Multiple layers of security
- **Least Privilege**: Minimum necessary access
- **Zero Trust**: Verify everything
- **Security by Design**: Build security from the start
- **Fail Securely**: Fail safe, not open

---

## OWASP Top 10 (2021)

### 1. Broken Access Control

**Vulnerability**: Users can access unauthorized resources

```typescript
// ❌ Bad: No authorization check
app.get('/api/users/:id/profile', async (req, res) => {
  const profile = await db.user.findUnique({
    where: { id: parseInt(req.params.id) }
  })
  res.json(profile)
})

// ✅ Good: Verify user can access this resource
app.get('/api/users/:id/profile', authenticate, async (req, res) => {
  const requestedId = parseInt(req.params.id)

  // Users can only access their own profile (or admins can access any)
  if (req.user.id !== requestedId && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' })
  }

  const profile = await db.user.findUnique({
    where: { id: requestedId }
  })
  res.json(profile)
})
```

### 2. Cryptographic Failures

**Vulnerability**: Sensitive data exposed due to weak crypto

```typescript
import bcrypt from 'bcrypt'
import crypto from 'crypto'

// ✅ Password hashing (never store plaintext!)
async function hashPassword(password: string): Promise<string> {
  const salt = await bcrypt.genSalt(12) // Cost factor: 12
  return await bcrypt.hash(password, salt)
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return await bcrypt.compare(password, hash)
}

// ✅ Encrypt sensitive data at rest
const algorithm = 'aes-256-gcm'
const key = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex') // 32 bytes

function encrypt(text: string): string {
  const iv = crypto.randomBytes(16)
  const cipher = crypto.createCipheriv(algorithm, key, iv)

  let encrypted = cipher.update(text, 'utf8', 'hex')
  encrypted += cipher.final('hex')

  const authTag = cipher.getAuthTag()

  return iv.toString('hex') + ':' + authTag.toString('hex') + ':' + encrypted
}

function decrypt(encrypted: string): string {
  const parts = encrypted.split(':')
  const iv = Buffer.from(parts[0], 'hex')
  const authTag = Buffer.from(parts[1], 'hex')
  const encryptedText = parts[2]

  const decipher = crypto.createDecipheriv(algorithm, key, iv)
  decipher.setAuthTag(authTag)

  let decrypted = decipher.update(encryptedText, 'hex', 'utf8')
  decrypted += decipher.final('utf8')

  return decrypted
}

// ✅ HTTPS only in production
app.use((req, res, next) => {
  if (process.env.NODE_ENV === 'production' && !req.secure) {
    return res.redirect(`https://${req.headers.host}${req.url}`)
  }
  next()
})
```

### 3. Injection (SQL, NoSQL, Command)

**Vulnerability**: Attacker can inject malicious code

```typescript
// ❌ Bad: SQL Injection vulnerability
app.get('/users', (req, res) => {
  const { search } = req.query
  db.query(`SELECT * FROM users WHERE name = '${search}'`) // DANGEROUS!
})

// ✅ Good: Parameterized queries
app.get('/users', async (req, res) => {
  const { search } = req.query
  const users = await db.query('SELECT * FROM users WHERE name = $1', [search])
  res.json(users)
})

// ✅ With Prisma (safe by default)
const users = await prisma.user.findMany({
  where: { name: search }
})

// ❌ Bad: NoSQL Injection
app.post('/login', async (req, res) => {
  const { username, password } = req.body
  const user = await db.collection('users').findOne({
    username: username,
    password: password // If attacker sends {$ne: null}, bypasses check!
  })
})

// ✅ Good: Validate input types
app.post('/login', async (req, res) => {
  const { username, password } = req.body

  if (typeof username !== 'string' || typeof password !== 'string') {
    return res.status(400).json({ error: 'Invalid input' })
  }

  const user = await db.collection('users').findOne({ username })

  if (!user || !(await bcrypt.compare(password, user.password))) {
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  // Generate token
})

// ❌ Bad: Command Injection
import { exec } from 'child_process'

app.get('/ping', (req, res) => {
  const { host } = req.query
  exec(`ping -c 4 ${host}`, (err, stdout) => { // DANGEROUS!
    res.send(stdout)
  })
})

// ✅ Good: Never execute user input directly
// Use safe alternatives or sanitize strictly
import { execFile } from 'child_process'

app.get('/ping', (req, res) => {
  const { host } = req.query

  // Validate input (whitelist approach)
  if (!/^[a-zA-Z0-9.-]+$/.test(host)) {
    return res.status(400).json({ error: 'Invalid host' })
  }

  execFile('ping', ['-c', '4', host], (err, stdout) => {
    if (err) return res.status(500).json({ error: 'Ping failed' })
    res.send(stdout)
  })
})
```

### 4. Insecure Design

**Vulnerability**: Missing security controls

```typescript
// ✅ Implement rate limiting
import rateLimit from 'express-rate-limit'

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts
  message: 'Too many login attempts, please try again later'
})

app.post('/auth/login', loginLimiter, async (req, res) => {
  // Login logic
})

// ✅ Implement account lockout
async function checkAccountLockout(email: string): Promise<boolean> {
  const attempts = await redis.get(`login_attempts:${email}`)

  if (attempts && parseInt(attempts) >= 5) {
    const lockoutUntil = await redis.ttl(`login_attempts:${email}`)
    return lockoutUntil > 0 // Still locked
  }

  return false
}

async function recordFailedLogin(email: string) {
  const key = `login_attempts:${email}`
  await redis.incr(key)
  await redis.expire(key, 15 * 60) // 15 minutes
}

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body

  if (await checkAccountLockout(email)) {
    return res.status(429).json({ error: 'Account temporarily locked' })
  }

  const user = await db.user.findUnique({ where: { email } })

  if (!user || !(await bcrypt.compare(password, user.password))) {
    await recordFailedLogin(email)
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  // Clear failed attempts on success
  await redis.del(`login_attempts:${email}`)

  // Generate token
})
```

### 5. Security Misconfiguration

```typescript
// ✅ Secure HTTP headers (use helmet)
import helmet from 'helmet'

app.use(helmet())

// Custom headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('X-Frame-Options', 'DENY')
  res.setHeader('X-XSS-Protection', '1; mode=block')
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
  next()
})

// ✅ CORS configuration
import cors from 'cors'

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}))

// ✅ Hide server information
app.disable('x-powered-by')

// ✅ Environment-specific configs
if (process.env.NODE_ENV === 'production') {
  // Disable error stack traces
  app.use((err, req, res, next) => {
    res.status(500).json({ error: 'Internal server error' })
  })
} else {
  // Development: show detailed errors
  app.use((err, req, res, next) => {
    res.status(500).json({ error: err.message, stack: err.stack })
  })
}
```

### 6. Vulnerable Components

```bash
# ✅ Regular dependency audits
npm audit
npm audit fix

# ✅ Use Snyk or Dependabot
npx snyk test
npx snyk monitor

# ✅ Keep dependencies updated
npm outdated
npm update

# ✅ Lock file integrity
npm ci  # Use in CI/CD (respects package-lock.json exactly)
```

### 7. Authentication Failures

```typescript
import jwt from 'jsonwebtoken'

// ✅ Secure JWT implementation
function generateToken(userId: number): string {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET!,
    {
      expiresIn: '7d',
      issuer: 'myapp.com',
      audience: 'myapp.com'
    }
  )
}

function verifyToken(token: string): any {
  try {
    return jwt.verify(token, process.env.JWT_SECRET!, {
      issuer: 'myapp.com',
      audience: 'myapp.com'
    })
  } catch (error) {
    throw new Error('Invalid token')
  }
}

// ✅ Secure session management
import session from 'express-session'
import RedisStore from 'connect-redis'

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  name: 'sessionId', // Don't use default 'connect.sid'
  cookie: {
    secure: process.env.NODE_ENV === 'production', // HTTPS only
    httpOnly: true, // Prevent XSS
    maxAge: 1000 * 60 * 60 * 24 * 7, // 1 week
    sameSite: 'strict' // CSRF protection
  }
}))

// ✅ Multi-factor authentication (2FA)
import speakeasy from 'speakeasy'

// Generate secret for user
const secret = speakeasy.generateSecret({ name: 'MyApp (user@example.com)' })

// Save secret.base32 to user record

// Verify TOTP
const verified = speakeasy.totp.verify({
  secret: user.totpSecret,
  encoding: 'base32',
  token: userProvidedCode,
  window: 2 // Allow 2 time steps before/after
})
```

### 8. Software and Data Integrity Failures

```typescript
// ✅ Verify file uploads
import crypto from 'crypto'

function calculateHash(buffer: Buffer): string {
  return crypto.createHash('sha256').update(buffer).digest('hex')
}

app.post('/upload', upload.single('file'), async (req, res) => {
  const file = req.file
  const expectedHash = req.body.hash

  const actualHash = calculateHash(file.buffer)

  if (actualHash !== expectedHash) {
    return res.status(400).json({ error: 'File integrity check failed' })
  }

  // Process file
})

// ✅ Code signing (for deployments)
// Use GPG signatures for releases

// ✅ Subresource Integrity (SRI) for CDN
// <script src="https://cdn.example.com/lib.js"
//         integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/ux..."
//         crossorigin="anonymous"></script>
```

### 9. Security Logging & Monitoring

```typescript
import winston from 'winston'

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'security.log', level: 'warn' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
})

// ✅ Log security events
function logSecurityEvent(type: string, details: any) {
  logger.warn('Security Event', {
    type,
    timestamp: new Date().toISOString(),
    ...details
  })
}

// Examples
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body

  const user = await db.user.findUnique({ where: { email } })

  if (!user || !(await bcrypt.compare(password, user.password))) {
    logSecurityEvent('FAILED_LOGIN', {
      email,
      ip: req.ip,
      userAgent: req.headers['user-agent']
    })
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  logSecurityEvent('SUCCESSFUL_LOGIN', {
    userId: user.id,
    email: user.email,
    ip: req.ip
  })

  // Generate token
})

// ✅ Monitor suspicious activity
async function detectAnomalies(userId: number, ip: string) {
  const recentIPs = await redis.smembers(`user:${userId}:ips`)

  if (!recentIPs.includes(ip)) {
    logSecurityEvent('NEW_IP_LOGIN', { userId, ip, previousIPs: recentIPs })

    // Send email notification
    await sendEmail(user.email, 'New login from unfamiliar location', ...)
  }

  await redis.sadd(`user:${userId}:ips`, ip)
  await redis.expire(`user:${userId}:ips`, 30 * 24 * 60 * 60) // 30 days
}
```

### 10. Server-Side Request Forgery (SSRF)

```typescript
// ❌ Bad: User controls URL
app.get('/fetch', async (req, res) => {
  const { url } = req.query
  const response = await fetch(url) // DANGEROUS! Can access internal services
  res.json(await response.json())
})

// ✅ Good: Whitelist allowed domains
const ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com']

app.get('/fetch', async (req, res) => {
  const { url } = req.query

  try {
    const parsedUrl = new URL(url)

    if (!ALLOWED_DOMAINS.includes(parsedUrl.hostname)) {
      return res.status(400).json({ error: 'Invalid domain' })
    }

    // Prevent access to private IPs
    const ipRegex = /^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/
    if (ipRegex.test(parsedUrl.hostname)) {
      return res.status(400).json({ error: 'Private IPs not allowed' })
    }

    const response = await fetch(url)
    res.json(await response.json())
  } catch (error) {
    res.status(400).json({ error: 'Invalid URL' })
  }
})
```

---

## Security Checklist

### Authentication & Authorization
- [ ] Passwords hashed with bcrypt (cost >= 12)
- [ ] JWT tokens signed and verified
- [ ] Tokens expire (reasonable TTL)
- [ ] Refresh token rotation
- [ ] MFA available for sensitive operations
- [ ] Account lockout after failed attempts
- [ ] Authorization checked on every request

### Data Protection
- [ ] HTTPS enforced in production
- [ ] Sensitive data encrypted at rest
- [ ] Database credentials in environment variables
- [ ] API keys rotated regularly
- [ ] PII data anonymized/pseudonymized
- [ ] Secure file upload validation

### Input Validation
- [ ] All inputs validated (type, format, range)
- [ ] SQL queries parameterized
- [ ] XSS protection (escape output)
- [ ] CSRF tokens for state-changing operations
- [ ] File upload size limits
- [ ] Content-Type validation

### Infrastructure
- [ ] Security headers configured (helmet)
- [ ] CORS properly configured
- [ ] Rate limiting on APIs
- [ ] DDoS protection (CloudFlare, AWS Shield)
- [ ] Regular dependency updates
- [ ] Security audit logs
- [ ] Error messages don't leak info

---

**Remember**: Security is not a feature, it's a requirement. Think like an attacker, defend in depth, and always fail securely.

**Created**: 2026-02-04
**Maintained By**: Google Blockchain Security
**Version**: OWASP Top 10 (2021)
