# Chaos Engineering Experiments

Example chaos experiments from Netflix.

## Example 1: Database Failover Test

Test automatic failover to read replicas.

```python
def test_database_failover():
    """
    Hypothesis: If primary database fails,
    app will automatically failover to read replicas
    with <5 seconds downtime
    """

    # Step 1: Measure baseline
    baseline_latency = measure_db_latency()

    # Step 2: Inject failure - block primary DB
    chaos.block_network(
        target="primary-db.example.com",
        port=5432,
        duration="5m"
    )

    # Step 3: Measure impact
    time.sleep(10)  # Wait for detection
    failover_latency = measure_db_latency()

    # Step 4: Verify failover
    assert failover_latency < 5000, "Failover took too long"
    assert get_success_rate() > 99.5%, "Success rate dropped"

    # Step 5: Cleanup
    chaos.restore_network()
```

## Example 2: Dependency Failure

Test graceful degradation when recommendation service fails.

```python
def test_recommendation_service_failure():
    """
    Hypothesis: If recommendation service fails,
    video streaming continues with fallback recommendations
    """

    # Inject failure
    chaos.fail_service(
        service="recommendation-service",
        failure_type="timeout",
        timeout_ms=30000  # 30 second timeout
    )

    # Verify behavior
    response = get_homepage()

    assert response.status == 200
    assert response.videos  # Fallback videos shown
    assert response.latency < 1000  # Fast timeout, not hung
    assert response.recommendation_source == "fallback"
```

## Example 3: Network Partition

Simulate network split between availability zones.

```python
def test_cross_az_partition():
    """
    Hypothesis: System handles network partition between AZs
    by routing traffic only to healthy AZs
    """

    # Create network partition
    chaos.partition_network(
        source_az="us-east-1a",
        target_az="us-east-1b",
        duration="10m"
    )

    # Measure impact
    metrics = {
        'us-east-1a': measure_az_health('us-east-1a'),
        'us-east-1b': measure_az_health('us-east-1b'),
        'us-east-1c': measure_az_health('us-east-1c')
    }

    # Each AZ should function independently
    for az, health in metrics.items():
        assert health['success_rate'] > 99%
        assert health['latency_p99'] < 200

    # Global metrics should remain stable
    assert get_global_success_rate() > 99.5%
```
