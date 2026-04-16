# Chaos Monkey Configuration

Netflix Chaos Monkey setup.

## Configuration

```yaml
# chaos-monkey-config.yml
chaos_monkey:
  enabled: true

  # Schedule (business hours only)
  schedule:
    - start_time: 09:00
      end_time: 15:00
      timezone: America/Los_Angeles
      weekdays: [Monday, Tuesday, Wednesday, Thursday, Friday]

  # Opt-in services
  opt_in:
    services:
      - video-service
      - recommendation-service
      - user-service

  # Termination strategy
  termination:
    strategy: random
    probability: 0.1  # 10% chance per hour
    group_type: ASG  # Auto Scaling Group

  # Exceptions
  exceptions:
    # Don't kill instances during critical events
    blackout_dates:
      - "2024-12-25"  # Christmas
      - "2024-01-01"  # New Year's
```

## How It Works

1. Chaos Monkey runs during business hours (09:00-15:00 PST)
2. Every hour, 10% chance of terminating a random instance
3. Only targets opt-in services
4. Respects blackout dates (holidays, major events)
5. Forces engineers to build auto-healing systems

## Safety Measures

- Business hours only (engineers available)
- Gradual rollout (1% → 10% → 100% of instances)
- Abort conditions (success rate thresholds)
- Blackout dates for critical periods
- Opt-in per service (not all at once)

## Expected Behavior

When Chaos Monkey terminates an instance:
1. Load balancer detects unhealthy instance
2. Auto-scaling group launches replacement
3. New instance becomes healthy
4. Traffic shifts to healthy instances
5. **No customer impact** - seamless failover
