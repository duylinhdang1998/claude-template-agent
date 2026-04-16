# Performance Requirements: [PROJECT_NAME]

**Author**: CTO - X Company
**Date**: [DATE]

---

## Performance Targets

### Frontend (Core Web Vitals)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | Lighthouse |
| **INP** (Interaction to Next Paint) | < 200ms | Lighthouse |
| **CLS** (Cumulative Layout Shift) | < 0.1 | Lighthouse |
| **FCP** (First Contentful Paint) | < 1.8s | Lighthouse |
| **TTFB** (Time to First Byte) | < 800ms | Lighthouse |
| **Lighthouse Score** | > 90 | Lighthouse |

### Backend (API Performance)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Response Time (p50)** | < 100ms | APM |
| **Response Time (p95)** | < 200ms | APM |
| **Response Time (p99)** | < 500ms | APM |
| **Error Rate** | < 0.1% | APM |
| **Throughput** | > 1000 req/s | Load test |
| **Uptime** | 99.9% | Monitoring |

### Database

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Query Time (p95)** | < 50ms | Query logs |
| **Connection Pool** | < 80% utilized | Monitoring |
| **Index Hit Ratio** | > 99% | Database stats |

---

## Load Requirements

### Expected Traffic

| Metric | Normal | Peak | Design Capacity |
|--------|--------|------|-----------------|
| Concurrent Users | [X] | [X * 3] | [X * 5] |
| Requests/Second | [X] | [X * 3] | [X * 5] |
| Data Volume | [X GB] | - | [X * 2 GB] |

### Scaling Strategy

| Component | Strategy | Trigger |
|-----------|----------|---------|
| API Servers | Horizontal auto-scale | CPU > 70% |
| Database | Read replicas | Read load |
| Cache | Redis cluster | Memory > 80% |
| Workers | Queue-based scale | Queue depth |

---

## Frontend Optimization

### Bundle Size Targets

| Bundle | Target | Current |
|--------|--------|---------|
| Main JS | < 200KB gzipped | [X KB] |
| CSS | < 50KB gzipped | [X KB] |
| Total Initial Load | < 300KB gzipped | [X KB] |

### Optimization Checklist
- [ ] Code splitting enabled
- [ ] Tree shaking configured
- [ ] Images optimized (WebP, lazy loading)
- [ ] Fonts optimized (subset, preload)
- [ ] Critical CSS inlined
- [ ] Service worker for caching
- [ ] Prefetching for navigation

---

## Backend Optimization

### API Optimization
- [ ] Response compression (gzip/brotli)
- [ ] ETags for caching
- [ ] Pagination on list endpoints
- [ ] Field selection (sparse fieldsets)
- [ ] N+1 query prevention

### Database Optimization
- [ ] Proper indexes on query columns
- [ ] Query analysis for slow queries
- [ ] Connection pooling configured
- [ ] Read replicas for heavy reads

### Caching Strategy

| Layer | Cache | TTL | Invalidation |
|-------|-------|-----|--------------|
| CDN | Static assets | 1 year | Version hash |
| API | Response cache | 5 min | Event-based |
| Application | Redis | Varies | Manual/TTL |
| Database | Query cache | 1 min | Write-through |

---

## Monitoring & Alerting

### Key Metrics to Monitor

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| Response Time p95 | > 200ms | > 500ms | Page oncall |
| Error Rate | > 0.5% | > 1% | Page oncall |
| CPU Usage | > 70% | > 90% | Auto-scale |
| Memory Usage | > 80% | > 95% | Investigate |
| Database Connections | > 80% | > 95% | Scale pool |

### Dashboards
- [ ] Real-time performance dashboard
- [ ] API endpoint metrics
- [ ] Database query performance
- [ ] Infrastructure metrics
- [ ] Business metrics

---

## Load Testing

### Test Scenarios

| Scenario | Users | Duration | Ramp |
|----------|-------|----------|------|
| Baseline | 100 | 10 min | 1 min |
| Normal Load | 500 | 30 min | 5 min |
| Peak Load | 1500 | 15 min | 3 min |
| Stress Test | 3000 | 10 min | 2 min |
| Soak Test | 500 | 4 hours | 10 min |

### Test Tools
- **Load Testing**: k6 / Artillery / Locust
- **APM**: DataDog / New Relic / Sentry
- **Monitoring**: Prometheus + Grafana

---

## Performance Budget

### Per-Route Budgets

| Route | JS | CSS | Images | Total |
|-------|----|----|--------|-------|
| Home | 100KB | 30KB | 200KB | 330KB |
| Dashboard | 150KB | 30KB | 50KB | 230KB |
| Detail Page | 120KB | 30KB | 300KB | 450KB |

### CI/CD Enforcement
- [ ] Bundle size check in CI
- [ ] Lighthouse CI integration
- [ ] Performance regression alerts

---

## Optimization Timeline

### Phase 1: Foundation
- [ ] Monitoring setup
- [ ] Baseline measurements
- [ ] Critical optimizations

### Phase 2: Optimization
- [ ] Frontend bundle optimization
- [ ] API response time optimization
- [ ] Database query optimization

### Phase 3: Scale
- [ ] Load testing complete
- [ ] Auto-scaling configured
- [ ] CDN optimized

---

**Approved By**: [CTO Name]
**Review Date**: [DATE]
