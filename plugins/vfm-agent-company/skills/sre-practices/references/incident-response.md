# Incident Response

Google's approach to handling production incidents.

## Incident Response Roles

**Incident Commander**:
- Coordinates response
- Makes decisions
- Communicates with stakeholders
- Delegates tasks

**Operations Lead**:
- Executes fixes
- Runs commands
- Deploys changes

**Communications Lead**:
- Updates status page
- Notifies stakeholders
- Manages external communication

**Subject Matter Expert (SME)**:
- Provides technical expertise
- Suggests solutions

## Incident Severity Levels

```yaml
SEV-1: Critical
  - Complete service outage
  - Data loss
  - Security breach
  - Page everyone, war room

SEV-2: High
  - Partial outage
  - Degraded performance
  - Affects significant users
  - Page on-call, coordinate response

SEV-3: Medium
  - Minor degradation
  - Affects small subset of users
  - Ticket, fix during business hours

SEV-4: Low
  - No user impact
  - Internal issue
  - Fix when convenient
```

## Incident Response Process

```
1. DETECT
   - Automated alerts
   - User reports
   - Monitoring dashboards

2. TRIAGE
   - Assess severity
   - Assign roles
   - Start incident channel

3. MITIGATE
   - Stop the bleeding
   - Restore service
   - Apply temporary fix

4. RESOLVE
   - Implement permanent fix
   - Verify metrics normal
   - Close incident

5. POSTMORTEM
   - Blameless review
   - Document timeline
   - Action items
```

## Blameless Postmortem Template

```markdown
# Postmortem: Video Service Outage (2024-01-15)

**Incident Date**: 2024-01-15 14:30-16:45 UTC
**Severity**: SEV-1
**Duration**: 2h 15m
**Impact**: 100% of video playback failed
**Root Cause**: Database connection pool exhausted

## Timeline
- 14:30 - Alerts fire: Video start success rate drops to 0%
- 14:35 - Incident declared, roles assigned
- 14:45 - Identified: DB connection pool at 100%
- 14:50 - Mitigation: Increased pool size from 10 to 100
- 15:00 - Service recovering, success rate 80%
- 15:15 - Full recovery, success rate 99.9%
- 16:45 - Incident closed after monitoring period

## Root Cause
Sudden traffic spike (3x normal) exhausted database connection pool.
Connection pool configured for average load, not peak load.

## Impact
- 2h 15m complete outage
- ~500K failed video starts
- Error budget for month EXHAUSTED

## What Went Well
- Fast detection (2 minutes)
- Clear roles and communication
- Mitigation applied quickly (15 minutes)

## What Went Wrong
- No auto-scaling for connection pool
- No alerts for connection pool saturation
- No load testing for 3x traffic

## Action Items
1. [P0] Implement connection pool auto-scaling (Owner: @alex, Due: 2024-01-20)
2. [P0] Add alerts for connection pool >80% (Owner: @sam, Due: 2024-01-18)
3. [P1] Run load tests for 5x traffic (Owner: @jordan, Due: 2024-01-25)
4. [P2] Document runbook for DB connection issues (Owner: @morgan, Due: 2024-02-01)

## Lessons Learned
- Always configure for peak load, not average
- Monitor resource saturation, not just errors
- Test for traffic spikes regularly
```

## Best Practices

1. **Blameless culture** - Focus on systems, not people
2. **Clear communication** - Regular updates to stakeholders
3. **Stop the bleeding first** - Mitigate before root cause
4. **Document everything** - Timeline, decisions, actions
5. **Follow up on action items** - Track to completion
