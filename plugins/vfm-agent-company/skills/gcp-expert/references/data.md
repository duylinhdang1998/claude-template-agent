# GCP Data & Analytics

## BigQuery

Petabyte-scale data warehouse. Process billions of rows in seconds.

### Example: Video Analytics

```sql
-- BigQuery SQL (YouTube-scale analytics)
SELECT
  DATE(timestamp) as date,
  video_id,
  COUNT(DISTINCT user_id) as unique_viewers,
  SUM(watch_time_seconds) as total_watch_time,
  AVG(watch_time_seconds) as avg_watch_time
FROM `youtube-analytics.raw.video_views`
WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY date, video_id
ORDER BY unique_viewers DESC
LIMIT 100;
```

### Partitioned Tables

```sql
-- Partition for performance
CREATE TABLE `project.dataset.events`
PARTITION BY DATE(timestamp)
CLUSTER BY user_id, event_type
AS SELECT * FROM `source.events`;
```

## Cloud Dataflow (Apache Beam)

Real-time streaming pipeline (Google uses for Search, YouTube):

```python
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

def run():
    options = PipelineOptions(
        project='my-project',
        runner='DataflowRunner',
        region='us-central1',
        streaming=True,
        autoscaling_algorithm='THROUGHPUT_BASED',
        max_num_workers=100
    )

    with beam.Pipeline(options=options) as pipeline:
        (pipeline
         | 'Read from Pub/Sub' >> beam.io.ReadFromPubSub(
             subscription='projects/my-project/subscriptions/events')
         | 'Parse JSON' >> beam.Map(parse_json)
         | 'Window 1-minute' >> beam.WindowInto(
             beam.window.FixedWindows(60))
         | 'Count by user' >> beam.combiners.Count.PerKey()
         | 'Write to BigQuery' >> beam.io.WriteToBigQuery(
             'project:dataset.user_counts',
             schema='user_id:STRING,count:INTEGER,timestamp:TIMESTAMP')
        )
```

## When to Use What

- **BigQuery**: Analytics, data warehouse, SQL queries on huge datasets
- **Dataflow**: Real-time streaming, ETL pipelines, complex transformations
