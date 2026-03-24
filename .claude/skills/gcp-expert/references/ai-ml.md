# GCP AI & Machine Learning

## Vertex AI

Google's unified ML platform.

### Train Custom Model

```python
from google.cloud import aiplatform

aiplatform.init(project='my-project', location='us-central1')

# Custom training job
job = aiplatform.CustomTrainingJob(
    display_name='custom-training',
    script_path='train.py',
    container_uri='gcr.io/cloud-aiplatform/training/tf-gpu.2-12:latest',
    requirements=['tensorflow==2.12.0', 'pandas'],
    model_serving_container_image_uri='gcr.io/cloud-aiplatform/prediction/tf2-gpu.2-12:latest'
)

# Run on TPU or GPU
model = job.run(
    dataset=dataset,
    replica_count=4,
    machine_type='n1-standard-16',
    accelerator_type='NVIDIA_TESLA_V100',
    accelerator_count=4
)
```

### Deploy Model to Endpoint

```python
def deploy_model(model):
    endpoint = aiplatform.Endpoint.create(display_name='prediction-endpoint')

    model.deploy(
        endpoint=endpoint,
        min_replica_count=2,
        max_replica_count=10,
        machine_type='n1-standard-4',
        accelerator_type='NVIDIA_TESLA_T4',
        accelerator_count=1
    )

    return endpoint
```

## AutoML

For common ML tasks without custom code:

- **AutoML Vision**: Image classification, object detection
- **AutoML Natural Language**: Text classification, sentiment analysis
- **AutoML Tables**: Structured data predictions

## When to Use What

- **Vertex AI Custom Training**: Custom models, full control, advanced ML
- **AutoML**: Quick ML solutions, no ML expertise needed
- **Pre-trained APIs**: Common tasks (translation, vision, speech)
