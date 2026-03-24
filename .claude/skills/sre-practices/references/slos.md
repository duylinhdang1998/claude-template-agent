# Service Level Objectives (SLOs)

Define and measure service quality.

## SLI, SLO, SLA

**SLI** (Service Level Indicator): Metric measuring service quality
- Availability: % of successful requests
- Latency: % of requests < threshold
- Throughput: requests/second
- Correctness: % of correct responses

**SLO** (Service Level Objective): Target for SLI
- "99.9% of requests succeed"
- "95% of requests <200ms latency"

**SLA** (Service Level Agreement): Contractual obligation
- Usually less strict than SLO
- Has financial penalties
- Example: "99.5% uptime or refund"

## Choosing Good SLOs

### Bad SLO Examples

```
❌ "System is fast"  - Not measurable
❌ "99.999% uptime"  - Too strict, slows development
❌ "All requests <100ms"  - Unrealistic
```

### Good SLO Examples

```
✅ "99.9% of API requests return 2xx/3xx status codes"
   - Measurable: HTTP status codes
   - Realistic: 0.1% error budget

✅ "95% of requests complete in <200ms"
   - Measurable: P95 latency
   - User-focused: Affects UX

✅ "99.5% of video playback starts successfully"
   - Measurable: Playback start events
   - Business-critical: Core feature
```

## Implementing SLOs

```python
# Prometheus queries for SLOs

# Availability SLO: 99.9% of requests succeed
availability_slo = """
sum(rate(http_requests_total{status=~"2..|3.."}[30d]))
/
sum(rate(http_requests_total[30d]))
"""

# Latency SLO: 95% of requests <200ms
latency_slo = """
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket[30d])
) < 0.2
```

## SLO Document Template

```markdown
# Video Service SLO

## SLI Definition
- **Metric**: Successful video playback starts
- **Success criteria**: Video begins playing within 3 seconds
- **Measurement**: Client-side playback start events

## SLO Target
- **Objective**: 99.9% of video starts succeed
- **Time window**: 30-day rolling window
- **Error budget**: 0.1% = 43 minutes/month

## Rationale
- User research shows 3-second tolerance
- 99.9% balances reliability with development velocity
- Covers 99% of user sessions

## Exclusions
- Requests from monitoring/health checks
- Requests with client errors (4xx)
- Requests during planned maintenance

## Alerting
- Alert when error budget 50% consumed
- Page when error budget 90% consumed
- Freeze releases when budget exhausted
```
