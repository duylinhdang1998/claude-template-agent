# API Design: [PROJECT_NAME]

**Author**: CTO - X Company
**Date**: [DATE]
**API Style**: REST / GraphQL

---

## Base URL

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:3000/api` |
| Staging | `https://staging.example.com/api` |
| Production | `https://api.example.com` |

---

## Authentication

### Strategy
- **Type**: Bearer Token (JWT)
- **Header**: `Authorization: Bearer <token>`
- **Token Expiry**: Access (15min), Refresh (7 days)

### Auth Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/register` | Create account | Public |
| POST | `/auth/login` | Get tokens | Public |
| POST | `/auth/refresh` | Refresh access token | Refresh Token |
| POST | `/auth/logout` | Invalidate tokens | Bearer |
| GET | `/auth/me` | Get current user | Bearer |

---

## API Endpoints

### [Resource 1: Users]

| Method | Endpoint | Description | Auth | Request | Response |
|--------|----------|-------------|------|---------|----------|
| GET | `/users` | List users | Admin | `?page=1&limit=20` | `User[]` |
| GET | `/users/:id` | Get user | Bearer | - | `User` |
| PATCH | `/users/:id` | Update user | Owner | `UpdateUserDto` | `User` |
| DELETE | `/users/:id` | Delete user | Admin | - | `204` |

### [Resource 2: Items]

| Method | Endpoint | Description | Auth | Request | Response |
|--------|----------|-------------|------|---------|----------|
| GET | `/items` | List items | Bearer | `?page=1&limit=20` | `Item[]` |
| POST | `/items` | Create item | Bearer | `CreateItemDto` | `Item` |
| GET | `/items/:id` | Get item | Bearer | - | `Item` |
| PATCH | `/items/:id` | Update item | Owner | `UpdateItemDto` | `Item` |
| DELETE | `/items/:id` | Delete item | Owner | - | `204` |

---

## Request/Response Formats

### Standard Response
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [
      { "field": "email", "message": "Email is required" }
    ]
  }
}
```

### Pagination
```
GET /items?page=1&limit=20&sort=createdAt&order=desc
```

---

## Data Models (DTOs)

### CreateUserDto
```typescript
{
  email: string;       // required, valid email
  password: string;    // required, min 8 chars
  name: string;        // required
}
```

### UpdateUserDto
```typescript
{
  name?: string;
  avatar?: string;
}
```

### UserResponse
```typescript
{
  id: string;
  email: string;
  name: string;
  avatar: string | null;
  createdAt: string;   // ISO 8601
  updatedAt: string;   // ISO 8601
}
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `UNAUTHORIZED` | 401 | Missing/invalid token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

---

## Rate Limiting

| Endpoint Type | Limit | Window |
|---------------|-------|--------|
| Auth endpoints | 5 req | 15 min |
| Public APIs | 100 req | 1 min |
| Authenticated APIs | 1000 req | 1 min |

**Headers**:
- `X-RateLimit-Limit`: Max requests
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Reset timestamp

---

## Versioning

- **Strategy**: URL path versioning (`/api/v1/...`)
- **Current Version**: v1
- **Deprecation Policy**: 6 months notice

---

## WebSocket Events (if applicable)

| Event | Direction | Payload | Description |
|-------|-----------|---------|-------------|
| `connect` | Server → Client | `{ userId }` | Connection established |
| `item:created` | Server → Client | `Item` | New item created |
| `item:updated` | Server → Client | `Item` | Item updated |
| `item:deleted` | Server → Client | `{ id }` | Item deleted |

---

**Approved By**: [CTO Name]
**Review Date**: [DATE]
