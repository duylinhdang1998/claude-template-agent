# GCP Databases

## Cloud SQL (Managed PostgreSQL/MySQL)

Create HA Cloud SQL instance:

```bash
gcloud sql instances create production-db \
  --database-version POSTGRES_15 \
  --tier db-custom-8-32768 \
  --region us-central1 \
  --availability-type REGIONAL \
  --backup-start-time 03:00 \
  --maintenance-window-day SUN \
  --maintenance-window-hour 4 \
  --enable-bin-log \
  --database-flags max_connections=500
```

## Cloud Spanner (Global Database)

Globally distributed, strongly consistent database (powers Google Ads, Google Play):

```python
from google.cloud import spanner

spanner_client = spanner.Client()
instance = spanner_client.instance('my-instance')
database = instance.database('my-database')

def insert_user(user_id, name, email):
    with database.batch() as batch:
        batch.insert(
            table='users',
            columns=('user_id', 'name', 'email', 'created_at'),
            values=[(user_id, name, email, spanner.COMMIT_TIMESTAMP)]
        )

# Read with strong consistency
def get_user(user_id):
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql(
            'SELECT * FROM users WHERE user_id = @user_id',
            params={'user_id': user_id},
            param_types={'user_id': spanner.param_types.STRING}
        )
        return list(results)
```

## Firestore (NoSQL Document Database)

Real-time NoSQL database (used by Google apps):

```python
from google.cloud import firestore

db = firestore.Client()

# Create document
def create_post(user_id, content):
    doc_ref = db.collection('posts').document()
    doc_ref.set({
        'user_id': user_id,
        'content': content,
        'created_at': firestore.SERVER_TIMESTAMP,
        'likes': 0
    })
    return doc_ref.id

# Real-time listeners
def watch_posts():
    posts_ref = db.collection('posts')

    def on_snapshot(col_snapshot, changes, read_time):
        for change in changes:
            if change.type.name == 'ADDED':
                print(f'New post: {change.document.id}')

    posts_ref.on_snapshot(on_snapshot)
```

## When to Use What

- **Cloud SQL**: Traditional relational database, PostgreSQL/MySQL compatibility
- **Cloud Spanner**: Global scale, strong consistency, horizontal scaling
- **Firestore**: Real-time sync, mobile/web apps, flexible schema
