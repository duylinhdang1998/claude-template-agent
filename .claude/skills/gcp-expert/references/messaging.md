# GCP Messaging & Events

## Cloud Pub/Sub

Google's messaging service (millions of messages/second scale):

### Publish Messages

```python
from google.cloud import pubsub_v1

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path('my-project', 'events')

def publish_event(event_data):
    data = json.dumps(event_data).encode('utf-8')
    future = publisher.publish(topic_path, data)
    return future.result()
```

### Subscribe to Messages

```python
subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path('my-project', 'events-sub')

def callback(message):
    print(f'Received: {message.data}')
    message.ack()

streaming_pull_future = subscriber.subscribe(subscription_path, callback)
```

## When to Use Pub/Sub

- Event-driven architectures
- Decouple microservices
- Real-time data streaming
- Message queues at scale
