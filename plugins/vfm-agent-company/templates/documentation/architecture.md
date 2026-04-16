# System Architecture Diagram

**Project**: [Project Name]
**System**: [System Name]
**Version**: [Version]
**Last Updated**: [Date]
**Architect**: [Architect Name]

---

## High-Level Architecture

```mermaid
graph TB
    Client[Client Applications]
    LB[Load Balancer]
    API[API Gateway]
    Auth[Auth Service]
    Backend1[Service 1]
    Backend2[Service 2]
    DB[(Database)]
    Cache[(Cache)]
    Queue[Message Queue]
    Storage[Object Storage]

    Client --> LB
    LB --> API
    API --> Auth
    API --> Backend1
    API --> Backend2
    Backend1 --> DB
    Backend1 --> Cache
    Backend2 --> DB
    Backend2 --> Queue
    Backend2 --> Storage
```

---

## Layer Breakdown (Clean Architecture)

```
┌─────────────────────────────────────────┐
│     External (UI, Database, APIs)       │
│  ┌───────────────────────────────────┐  │
│  │    Interface Adapters             │  │
│  │  (Controllers, Repositories)      │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Use Cases                  │  │  │
│  │  │  (Business Workflows)       │  │  │
│  │  │  ┌───────────────────────┐  │  │  │
│  │  │  │  Entities             │  │  │  │
│  │  │  │  (Core Domain)        │  │  │  │
│  │  │  └───────────────────────┘  │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘

Dependencies: Outside → Inside
```

---

## Component Diagram

```mermaid
graph LR
    subgraph "Client Layer"
        Web[Web App]
        Mobile[Mobile App]
        CLI[CLI Tool]
    end

    subgraph "API Layer"
        Gateway[API Gateway]
        Auth[Auth Service]
    end

    subgraph "Business Layer"
        UserSvc[User Service]
        OrderSvc[Order Service]
        PaymentSvc[Payment Service]
    end

    subgraph "Data Layer"
        PostgreSQL[(PostgreSQL)]
        Redis[(Redis)]
        S3[S3 Storage]
    end

    subgraph "Infrastructure"
        Queue[Message Queue]
        Monitor[Monitoring]
        Logs[Logging]
    end

    Web --> Gateway
    Mobile --> Gateway
    CLI --> Gateway

    Gateway --> Auth
    Gateway --> UserSvc
    Gateway --> OrderSvc
    Gateway --> PaymentSvc

    UserSvc --> PostgreSQL
    UserSvc --> Redis
    OrderSvc --> PostgreSQL
    OrderSvc --> Queue
    PaymentSvc --> PostgreSQL

    OrderSvc --> S3

    UserSvc -.-> Monitor
    OrderSvc -.-> Monitor
    PaymentSvc -.-> Monitor

    UserSvc -.-> Logs
    OrderSvc -.-> Logs
    PaymentSvc -.-> Logs
```

---

## Data Flow Diagram

### Example: Order Creation Flow

```mermaid
sequenceDiagram
    participant Client
    participant API Gateway
    participant Auth Service
    participant Order Service
    participant Payment Service
    participant Database
    participant Queue

    Client->>API Gateway: POST /orders
    API Gateway->>Auth Service: Validate Token
    Auth Service-->>API Gateway: Token Valid
    API Gateway->>Order Service: Create Order
    Order Service->>Database: Save Order
    Database-->>Order Service: Order Saved
    Order Service->>Payment Service: Process Payment
    Payment Service-->>Order Service: Payment Success
    Order Service->>Queue: Publish OrderCreated Event
    Order Service-->>API Gateway: Order Created
    API Gateway-->>Client: 201 Created
```

---

## Deployment Architecture

```mermaid
graph TB
    subgraph "Production (AWS)"
        subgraph "VPC"
            subgraph "Public Subnet"
                ALB[Application Load Balancer]
            end

            subgraph "Private Subnet 1"
                API1[API Server 1]
                API2[API Server 2]
            end

            subgraph "Private Subnet 2"
                Worker1[Worker 1]
                Worker2[Worker 2]
            end

            subgraph "Database Subnet"
                RDS[(RDS PostgreSQL)]
                ElastiCache[(ElastiCache Redis)]
            end
        end

        S3[S3 Bucket]
        CloudWatch[CloudWatch]
        SQS[SQS Queue]
    end

    Internet[Internet] --> ALB
    ALB --> API1
    ALB --> API2
    API1 --> RDS
    API2 --> RDS
    API1 --> ElastiCache
    API2 --> ElastiCache
    API1 --> S3
    API2 --> SQS
    Worker1 --> SQS
    Worker2 --> SQS
    Worker1 --> RDS
    Worker2 --> RDS

    API1 -.-> CloudWatch
    API2 -.-> CloudWatch
    Worker1 -.-> CloudWatch
    Worker2 -.-> CloudWatch
```

---

## Technology Stack

### Frontend
- **Framework**: [e.g., React 18 with TypeScript]
- **State Management**: [e.g., Redux Toolkit]
- **UI Library**: [e.g., Material-UI]
- **Build Tool**: [e.g., Vite]

### Backend
- **Language**: [e.g., Node.js 20 / Python 3.11]
- **Framework**: [e.g., Express.js / FastAPI]
- **API Style**: [e.g., REST / GraphQL]
- **Validation**: [e.g., Zod / Pydantic]

### Database
- **Primary**: [e.g., PostgreSQL 15]
- **Cache**: [e.g., Redis 7]
- **Search**: [e.g., Elasticsearch] (if applicable)
- **Object Storage**: [e.g., AWS S3]

### Infrastructure
- **Cloud Provider**: [e.g., AWS / GCP / Azure]
- **Container**: [e.g., Docker]
- **Orchestration**: [e.g., Kubernetes / ECS]
- **CI/CD**: [e.g., GitHub Actions]
- **Monitoring**: [e.g., DataDog / Prometheus + Grafana]

---

## ⭐ File Blueprint (MANDATORY — CTO fills this)

**Every file = 1 responsibility. Every component = its own file. Dev agents follow this as their map.**
**Code quality rules (Clean Code, DRY, SOLID, Error Handling) → see `helpers/code-quality.md`**

### Structure: Feature-Sliced Design

```
app/                                    # ALL application code
│
├── features/                           # Domain modules (self-contained)
│   │
│   ├── [domain]/                       # e.g. auth/, order/, member/, tree/
│   │   ├── components/                 # UI for this domain ONLY
│   │   │   ├── [Component].tsx         # 1 file = 1 component (STRICT)
│   │   │   └── [Component].tsx         # [What it renders, key props]
│   │   ├── hooks/                      # Domain-specific hooks
│   │   │   └── use[Hook].ts           # [What state/logic it encapsulates]
│   │   ├── api/                        # API routes for this domain
│   │   │   └── route.ts               # [HTTP methods, what it does]
│   │   ├── lib/                        # Domain logic & helpers
│   │   │   └── [helper].ts            # [Pure functions, business rules]
│   │   ├── types.ts                    # Domain types & interfaces
│   │   ├── [domain].test.ts            # Unit tests (colocated)
│   │   └── index.ts                    # Public API — ONLY export from here
│   │
│   └── [domain-2]/                     # Each domain follows same structure
│       └── ...
│
├── shared/                             # Cross-domain reusables ONLY
│   ├── ui/                             # Generic UI (Button, Modal, Input)
│   │   └── [Component].tsx             # 1 file = 1 component
│   ├── hooks/                          # Generic hooks (useDebounce, useLocalStorage)
│   │   └── use[Hook].ts
│   ├── lib/                            # Utilities (formatDate, cn, validators)
│   │   └── [util].ts
│   └── types.ts                        # Global types (ApiResponse, Pagination)
│
├── app/                                # Routing layer (THIN — compose, don't implement)
│   ├── page.tsx                        # [Home — composes features/*, no business logic]
│   ├── [route]/page.tsx                # [Route page — composes features/*]
│   ├── layout.tsx                      # Root layout
│   └── globals.css                     # Global styles
│
├── e2e/                                # E2E tests (cross-feature flows)
│   └── [flow].spec.ts                  # [User journey it validates]
│
└── prisma/                             # Database (if applicable)
    ├── schema.prisma                   # Database schema
    └── seed.ts                         # Seed data
```

### Import Boundary Rules

```
┌──────────────────────────────────────────────────┐
│  ALLOWED                                         │
│  app/pages    ──imports──►  features/*/index.ts   │
│  features/*   ──imports──►  shared/*              │
│  shared/*     ──imports──►  (external libs only)  │
│  e2e/         ──imports──►  (test utils only)     │
├──────────────────────────────────────────────────┤
│  FORBIDDEN                                       │
│  features/A   ──CANNOT──►   features/B            │
│  shared/*     ──CANNOT──►   features/*            │
│  features/*   ──CANNOT──►   app/pages             │
├──────────────────────────────────────────────────┤
│  CROSS-FEATURE COMMUNICATION                     │
│  → Via shared types/events in shared/             │
│  → Via parent page composition in app/            │
│  → Via shared store/context in shared/hooks/      │
└──────────────────────────────────────────────────┘
```

### Agent Ownership (PM uses this for task assignment)

| Module | Owner Agent | Responsibility |
|--------|-------------|----------------|
| `features/*/components/` | meta-react-architect | Domain UI |
| `features/*/api/` | netflix-backend-architect | Domain API routes |
| `features/*/lib/` | (task owner) | Domain business logic |
| `features/*/hooks/` | meta-react-architect | Domain state/effects |
| `shared/ui/` | meta-react-architect | Design system components |
| `shared/lib/` | (task owner) | Cross-domain utilities |
| `app/` (routing) | meta-react-architect | Page composition |
| `prisma/` | netflix-backend-architect | Schema & migrations |
| `e2e/` | google-qa-engineer | E2E test suites |
| `*.test.ts` | google-qa-engineer | Unit/integration tests |

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Components | PascalCase, 1 file each | `MemberDetail.tsx` |
| Hooks | `use` + PascalCase | `useTreeLayout.ts` |
| Lib/Utils | kebab-case | `tree-layout.ts` |
| Types | PascalCase noun | `Member`, `FamilyStore` |
| Stores | `use` + noun + `Store` | `useFamilyStore.ts` |
| Unit tests | `{domain}.test.ts` | `auth.test.ts` |
| E2E tests | `{flow}.spec.ts` | `login-flow.spec.ts` |
| Constants | UPPER_SNAKE_CASE | `MAX_TREE_DEPTH` |
| Feature index | `index.ts` always | Public API of the module |

### Rules

- 1 file = 1 component, 1 hook, or 1 utility (STRICT — no multi-export grab bags)
- Every file in blueprint MUST have a `# responsibility` comment
- Max 300 lines per file — split if larger
- Features import shared, NEVER import other features
- `index.ts` = public API of each feature — internal files are private
- New file needed? CTO updates blueprint FIRST, then PM creates task
- Tests colocated with feature (`[domain].test.ts`), E2E in `e2e/`

---

## Security Architecture

```
┌─────────────────────────────────────┐
│         Security Layers             │
├─────────────────────────────────────┤
│ 1. Network: VPC, Security Groups    │
│ 2. Transport: HTTPS/TLS 1.3         │
│ 3. Auth: JWT + OAuth 2.0            │
│ 4. Authorization: RBAC              │
│ 5. Data: Encryption at rest/transit │
│ 6. Application: Input validation    │
│ 7. Monitoring: WAF, IDS/IPS         │
└─────────────────────────────────────┘
```

**Security Measures**:
- [ ] HTTPS enforced
- [ ] JWT token authentication
- [ ] Role-based access control (RBAC)
- [ ] Input validation & sanitization
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF protection
- [ ] Rate limiting
- [ ] Secrets management (AWS Secrets Manager / Vault)
- [ ] Database encryption at rest
- [ ] Audit logging

---

## Scalability Strategy

### Horizontal Scaling
- **API Servers**: Auto-scaling based on CPU/memory
- **Workers**: Scale based on queue length
- **Database**: Read replicas for read-heavy workloads

### Caching Strategy
```
Client → CDN → API Gateway → Redis Cache → Database
         ↓        ↓              ↓            ↓
       Static   API Routes    Hot Data    Source of Truth
```

**Cache Levels**:
1. **CDN**: Static assets (images, CSS, JS)
2. **Application**: Frequently accessed data (user sessions, config)
3. **Database**: Query result cache

### Load Balancing
- **Algorithm**: Round-robin with health checks
- **Session Affinity**: Sticky sessions (if needed)
- **Health Checks**: HTTP /health endpoint every 30s

---

## Monitoring & Observability

### Metrics to Track
- **Application**: Response time, error rate, throughput
- **Infrastructure**: CPU, memory, disk, network
- **Business**: Orders/sec, revenue, user signups

### Logging Strategy
```
Application → Structured Logs → Log Aggregator → Dashboards
              (JSON format)      (CloudWatch)     (Grafana)
```

### Alerting
- **Critical**: P0 - Page immediately (5xx errors, service down)
- **Warning**: P1 - Notify team (high latency, increased errors)
- **Info**: P2 - Log only (threshold warnings)

---

## Disaster Recovery

### Backup Strategy
- **Database**: Daily backups + point-in-time recovery (PITR)
- **Object Storage**: Versioning enabled
- **Retention**: 30 days for all backups

### Recovery Objectives
- **RTO** (Recovery Time Objective): < 1 hour
- **RPO** (Recovery Point Objective): < 15 minutes

### High Availability
- **Multi-AZ Deployment**: Services across 3 availability zones
- **Database Replication**: Primary + read replicas
- **Failover**: Automatic failover for database

---

## API Design

### REST Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | /api/v1/users | List users | ✅ Admin |
| GET | /api/v1/users/:id | Get user | ✅ User |
| POST | /api/v1/users | Create user | ❌ Public |
| PATCH | /api/v1/users/:id | Update user | ✅ User |
| DELETE | /api/v1/users/:id | Delete user | ✅ Admin |

### Response Format
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

---

## Performance Requirements

| Metric | Target | Current |
|--------|--------|---------|
| **API Response Time (p95)** | < 200ms | [TBD] |
| **API Response Time (p99)** | < 500ms | [TBD] |
| **Throughput** | > 1000 req/s | [TBD] |
| **Database Query Time** | < 50ms | [TBD] |
| **Uptime** | 99.9% | [TBD] |
| **Error Rate** | < 0.1% | [TBD] |

---

## Architectural Decisions

### ADR-001: Use PostgreSQL for Primary Database
- **Date**: [Date]
- **Status**: Accepted
- **Context**: Need reliable ACID-compliant database
- **Decision**: Use PostgreSQL 15
- **Consequences**:
  - ✅ Strong consistency, mature ecosystem
  - ❌ More complex scaling than NoSQL

### ADR-002: Implement Clean Architecture
- **Date**: [Date]
- **Status**: Accepted
- **Context**: Long-term maintainability required
- **Decision**: Use Clean Architecture with DDD
- **Consequences**:
  - ✅ Testable, framework-independent
  - ❌ More initial complexity

---

**Approved By**: [Name]
**Review Date**: [Date]
**Next Review**: [Date + 3 months]
