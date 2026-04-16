# Tech Stack: [PROJECT_NAME]

**Author**: CTO - X Company
**Date**: [DATE]
**Status**: PENDING APPROVAL

---

## Stack Summary

| Layer | Technology | Version | Rationale |
|-------|-----------|---------|-----------|
| Frontend | [React/Next.js/Vue] | [X.x] | [Why chosen] |
| UI Library | [TailwindCSS/MUI/etc] | [X.x] | [Why chosen] |
| Language | [TypeScript/JavaScript] | [X.x] | [Why chosen] |
| Backend | [Node.js/Python/Go] | [X.x] | [Why chosen] |
| Framework | [Express/FastAPI/Gin] | [X.x] | [Why chosen] |
| ORM | [Prisma/TypeORM/SQLAlchemy] | [X.x] | [Why chosen] |
| Database | [PostgreSQL/MongoDB] | [X.x] | [Why chosen] |
| Cache | [Redis/Memcached] | [X.x] | [Why chosen] |
| Auth | [NextAuth/Passport/JWT] | [X.x] | [Why chosen] |
| Deployment | [Vercel/AWS/GCP] | - | [Why chosen] |
| CI/CD | [GitHub Actions/GitLab CI] | - | [Why chosen] |

---

## Frontend Stack

### Core
- **Framework**: [Next.js 14+ / React 18+ / Vue 3]
- **Language**: TypeScript 5.x
- **Styling**: [TailwindCSS / CSS Modules / Styled Components]
- **State Management**: [Zustand / Redux / React Context]
- **Data Fetching**: [TanStack Query / SWR / RTK Query]

### UI Components
- **Component Library**: [shadcn/ui / MUI / Ant Design / Custom]
- **Icons**: [Lucide / Heroicons / FontAwesome]
- **Animations**: [Framer Motion / CSS Transitions]

### Build & Dev
- **Bundler**: [Vite / Turbopack / Webpack]
- **Linting**: ESLint + Prettier
- **Testing**: [Jest / Vitest] + [Playwright / Cypress]

---

## Backend Stack

### Core
- **Runtime**: [Node.js 20+ / Python 3.11+ / Go 1.21+]
- **Framework**: [Express / FastAPI / Gin / Spring Boot]
- **Language**: [TypeScript / Python / Go / Java]

### Database
- **Primary**: [PostgreSQL 16 / MongoDB 7 / MySQL 8]
- **ORM/ODM**: [Prisma / TypeORM / SQLAlchemy / Mongoose]
- **Migrations**: [Prisma Migrate / Alembic / golang-migrate]

### Caching & Queues
- **Cache**: [Redis 7 / Memcached]
- **Message Queue**: [BullMQ / RabbitMQ / SQS]
- **Background Jobs**: [BullMQ / Celery / Temporal]

### Authentication
- **Strategy**: [JWT + Refresh Tokens / OAuth2 / Session]
- **Library**: [NextAuth.js / Passport.js / FastAPI Security]
- **Password Hashing**: [bcrypt / Argon2]

---

## Infrastructure

### Cloud Provider
- **Primary**: [AWS / GCP / Azure / Vercel]
- **Region**: [us-east-1 / ap-southeast-1]
- **Multi-AZ**: [Yes / No]

### Deployment
- **Container**: [Docker / Podman]
- **Orchestration**: [Kubernetes / ECS / Cloud Run]
- **CI/CD**: [GitHub Actions / GitLab CI / CircleCI]

### Monitoring
- **APM**: [DataDog / New Relic / Sentry]
- **Logging**: [CloudWatch / Loki / ELK]
- **Metrics**: [Prometheus + Grafana / CloudWatch]

---

## Third-Party Services

| Service | Provider | Purpose |
|---------|----------|---------|
| Email | [SendGrid / Resend / SES] | Transactional emails |
| Storage | [S3 / Cloudflare R2 / GCS] | File uploads |
| CDN | [CloudFront / Cloudflare] | Static assets |
| Payments | [Stripe / PayPal] | Payment processing |
| Analytics | [Mixpanel / PostHog / GA4] | Product analytics |

---

## Development Setup

### Prerequisites
```bash
node >= 20.0.0
npm >= 10.0.0
docker >= 24.0.0
```

### Local Development
```bash
# Clone and install
git clone [repo-url]
npm install

# Environment
cp .env.example .env.local

# Database
docker-compose up -d
npx prisma db push

# Run
npm run dev
```

---

## Stack Decisions (ADRs)

### ADR-001: [Decision Title]
- **Date**: [DATE]
- **Status**: Accepted
- **Context**: [Why decision needed]
- **Decision**: [What was decided]
- **Consequences**: [Trade-offs]

---

**Approved By**: [CTO Name]
**Review Date**: [DATE]
