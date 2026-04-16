# Error Budgets

Balance reliability vs velocity with error budgets.

## Concept

**Philosophy**: 100% uptime is the wrong target.
- Users can't tell difference between 99.99% and 100%
- Pursuing 100% slows down feature development
- Error budgets balance reliability vs velocity

## Error Budget Math

```
SLO: 99.9% uptime
→ Error budget: 0.1% = 43 minutes/month downtime allowed

SLO: 99.99% uptime
→ Error budget: 0.01% = 4.3 minutes/month

SLO: 99.5% uptime
→ Error budget: 0.5% = 3.6 hours/month
```

## Error Budget Policy

Define consequences when budget is exhausted:

```yaml
# error-budget-policy.yml
video-service:
  slo: 99.9%  # 43 min/month budget

  when_budget_remaining:
    - Deploy 3x per day
    - Ship experimental features
    - Take calculated risks
    - Focus on velocity

  when_budget_50_percent_consumed:
    - Review recent changes
    - Increase monitoring
    - Slow down releases
    - Deploy 1x per day

  when_budget_exhausted:
    - FREEZE: No new features
    - Focus 100% on reliability
    - Root cause analysis
    - Fix systemic issues
    - Resume features when budget recovers
```

## Measuring Error Budget

```python
# Calculate error budget consumption
def calculate_error_budget_consumption(slo, actual_uptime, period_days):
    """
    slo: 0.999 (99.9%)
    actual_uptime: 0.997 (99.7%)
    period_days: 30
    """
    error_budget = 1 - slo  # 0.001 = 0.1%
    actual_errors = 1 - actual_uptime  # 0.003 = 0.3%

    budget_consumed = actual_errors / error_budget  # 0.003 / 0.001 = 3.0
    budget_consumed_pct = budget_consumed * 100  # 300%

    return {
        'budget_consumed_pct': budget_consumed_pct,
        'status': 'EXHAUSTED' if budget_consumed >= 1 else 'OK',
        'downtime_minutes': actual_errors * period_days * 24 * 60
    }

# Example
result = calculate_error_budget_consumption(0.999, 0.997, 30)
# Result: {'budget_consumed_pct': 300%, 'status': 'EXHAUSTED', 'downtime_minutes': 129}
```

## Benefits

1. **Data-driven decisions** - Objective metric for reliability
2. **Aligned incentives** - Dev and SRE share error budget
3. **Innovation enablement** - Safe to take risks when budget available
4. **Automatic throttle** - System forces slowdown when unreliable
