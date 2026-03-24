# Security Architecture: [PROJECT_NAME]

**Author**: CTO - X Company
**Date**: [DATE]
**Classification**: Internal

---

## Security Overview

| Layer | Implementation | Status |
|-------|----------------|--------|
| Authentication | JWT + Refresh Tokens | [ ] |
| Authorization | RBAC | [ ] |
| Transport | HTTPS/TLS 1.3 | [ ] |
| Input Validation | Zod schemas | [ ] |
| SQL Injection | Prisma ORM | [ ] |
| XSS Prevention | React + CSP | [ ] |
| CSRF Protection | SameSite cookies | [ ] |
| Rate Limiting | Middleware | [ ] |
| Secrets Management | Env variables | [ ] |
| Dependency Audit | npm audit | [ ] |

---

## Authentication

### Strategy
- **Method**: JWT (JSON Web Tokens)
- **Access Token**: 15 minutes expiry
- **Refresh Token**: 7 days expiry, httpOnly cookie
- **Password Hashing**: bcrypt (12 rounds)

### Token Storage
| Token | Storage | Security |
|-------|---------|----------|
| Access Token | Memory / localStorage | Short-lived |
| Refresh Token | httpOnly cookie | SameSite=Strict |

### Session Management
- [ ] Tokens invalidated on logout
- [ ] Refresh token rotation
- [ ] Max concurrent sessions: [N]
- [ ] Force logout on password change

---

## Authorization

### Role-Based Access Control (RBAC)

| Role | Permissions |
|------|-------------|
| `admin` | Full access |
| `user` | Own resources only |
| `guest` | Public resources |

### Resource-Level Authorization
```
User can:
  - READ own profile
  - UPDATE own profile
  - DELETE own account

Admin can:
  - READ all users
  - UPDATE any user
  - DELETE any user
```

---

## Input Validation

### Server-Side (Mandatory)
- [ ] All inputs validated with Zod/Joi schemas
- [ ] Type checking on all API endpoints
- [ ] File upload restrictions (type, size)
- [ ] Sanitize HTML inputs

### Validation Rules
| Field | Rules |
|-------|-------|
| Email | Valid format, max 255 chars |
| Password | Min 8 chars, complexity requirements |
| Name | Max 100 chars, no HTML |
| File Upload | Max 10MB, allowed types only |

---

## OWASP Top 10 Mitigations

| Risk | Mitigation | Implementation |
|------|------------|----------------|
| A01: Broken Access Control | RBAC + ownership checks | Middleware |
| A02: Cryptographic Failures | TLS 1.3, bcrypt, secure cookies | Config |
| A03: Injection | Prisma ORM, parameterized queries | ORM |
| A04: Insecure Design | Threat modeling, code review | Process |
| A05: Security Misconfiguration | Secure defaults, hardened headers | Config |
| A06: Vulnerable Components | npm audit, Dependabot | CI/CD |
| A07: Auth Failures | Strong passwords, rate limiting | Middleware |
| A08: Data Integrity | Input validation, CSRF tokens | Middleware |
| A09: Logging Failures | Structured logging, no secrets | Logger |
| A10: SSRF | URL validation, allowlists | Validation |

---

## Security Headers

```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

---

## Data Protection

### Encryption
| Data | At Rest | In Transit |
|------|---------|------------|
| Passwords | bcrypt hash | HTTPS |
| PII | Database encryption | HTTPS |
| API Keys | Environment variables | HTTPS |
| Files | S3 SSE-S3 | HTTPS |

### Data Retention
| Data Type | Retention | Deletion |
|-----------|-----------|----------|
| User data | Account lifetime | On request |
| Logs | 30 days | Auto-purge |
| Backups | 30 days | Auto-purge |

---

## API Security

### Rate Limiting
| Endpoint | Limit | Action |
|----------|-------|--------|
| `/auth/*` | 5/15min | Block IP |
| `/api/*` | 100/min | 429 response |

### API Keys (if applicable)
- [ ] API keys hashed before storage
- [ ] Key rotation supported
- [ ] Key scoping (read/write)
- [ ] Usage logging

---

## Dependency Security

### Automated Scanning
- [ ] `npm audit` in CI/CD
- [ ] Dependabot enabled
- [ ] Snyk integration (optional)

### Update Policy
| Severity | SLA |
|----------|-----|
| Critical | 24 hours |
| High | 7 days |
| Medium | 30 days |
| Low | Next release |

---

## Incident Response

### Severity Levels
| Level | Description | Response Time |
|-------|-------------|---------------|
| P0 | Data breach, system down | Immediate |
| P1 | Security vulnerability | 4 hours |
| P2 | Suspicious activity | 24 hours |
| P3 | Minor issue | Next sprint |

### Contacts
| Role | Contact |
|------|---------|
| Security Lead | [email] |
| On-call | [phone] |

---

## Security Checklist

### Before Launch
- [ ] All OWASP Top 10 mitigated
- [ ] Security headers configured
- [ ] HTTPS enforced
- [ ] Rate limiting enabled
- [ ] Logging configured (no secrets)
- [ ] Dependency audit clean
- [ ] Penetration test passed
- [ ] Security review completed

---

**Approved By**: [CTO Name]
**Review Date**: [DATE]
**Next Review**: [DATE + 3 months]
