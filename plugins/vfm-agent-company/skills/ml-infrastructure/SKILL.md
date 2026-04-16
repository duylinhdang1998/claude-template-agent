---
name: ml-infrastructure
description: Machine Learning infrastructure and MLOps from Google AI. Use when building ML training pipelines, deploying models to production (TensorFlow Serving, TorchServe, Vertex AI), setting up feature stores, implementing model monitoring and drift detection, orchestrating ML workflows (Kubeflow, Airflow), or managing experiment tracking (MLflow, W&B). Triggers on MLOps, ML pipeline, model deployment, model serving, feature engineering, training infrastructure, or ML platform.
---

# ML Infrastructure - Machine Learning Pipelines & Deployment

**Purpose**: Build, train, and deploy machine learning models at scale with MLOps best practices

**Agent**: Google AI Researcher
**Use When**: Building ML pipelines, deploying models to production, or setting up ML infrastructure

---

## ML Pipeline Components

### 1. Data Pipeline

```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

# Load data
df = pd.read_csv('data.csv')

# Split features and target
X = df.drop('target', axis=1)
y = df['target']

# Train/test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Feature scaling
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Save preprocessor
import joblib
joblib.dump(scaler, 'models/scaler.pkl')
```

### 2. Model Training

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train_scaled, y_train)

# Evaluate
y_pred = model.predict(X_test_scaled)
accuracy = accuracy_score(y_test, y_pred)
print(f'Accuracy: {accuracy:.4f}')
print(classification_report(y_test, y_pred))

# Save model
joblib.dump(model, 'models/model.pkl')
```

### 3. Model Serving (FastAPI)

```python
from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np

app = FastAPI()

# Load model and scaler
model = joblib.load('models/model.pkl')
scaler = joblib.load('models/scaler.pkl')

class PredictionInput(BaseModel):
    features: list[float]

class PredictionOutput(BaseModel):
    prediction: int
    probability: float

@app.post('/predict', response_model=PredictionOutput)
async def predict(input_data: PredictionInput):
    # Preprocess
    features = np.array(input_data.features).reshape(1, -1)
    features_scaled = scaler.transform(features)

    # Predict
    prediction = model.predict(features_scaled)[0]
    probability = model.predict_proba(features_scaled)[0].max()

    return PredictionOutput(
        prediction=int(prediction),
        probability=float(probability)
    )

@app.get('/health')
async def health():
    return {'status': 'ok'}
```

---

## Deep Learning (PyTorch)

### Training

```python
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset

# Define model
class SimpleNN(nn.Module):
    def __init__(self, input_size, hidden_size, num_classes):
        super().__init__()
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size, num_classes)

    def forward(self, x):
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x

# Initialize
model = SimpleNN(input_size=10, hidden_size=64, num_classes=2)
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# Training loop
for epoch in range(100):
    for batch_x, batch_y in train_loader:
        # Forward pass
        outputs = model(batch_x)
        loss = criterion(outputs, batch_y)

        # Backward pass
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

    if (epoch + 1) % 10 == 0:
        print(f'Epoch [{epoch+1}/100], Loss: {loss.item():.4f}')

# Save model
torch.save(model.state_dict(), 'models/pytorch_model.pth')
```

### Inference

```python
# Load model
model = SimpleNN(input_size=10, hidden_size=64, num_classes=2)
model.load_state_dict(torch.load('models/pytorch_model.pth'))
model.eval()

# Predict
with torch.no_grad():
    input_tensor = torch.tensor(features, dtype=torch.float32)
    output = model(input_tensor)
    prediction = torch.argmax(output, dim=1)
```

---

## MLOps with MLflow

```python
import mlflow
import mlflow.sklearn

# Start MLflow run
with mlflow.start_run():
    # Log parameters
    mlflow.log_param('n_estimators', 100)
    mlflow.log_param('max_depth', 10)

    # Train model
    model = RandomForestClassifier(n_estimators=100, max_depth=10)
    model.fit(X_train, y_train)

    # Log metrics
    accuracy = accuracy_score(y_test, y_pred)
    mlflow.log_metric('accuracy', accuracy)

    # Log model
    mlflow.sklearn.log_model(model, 'model')

    print(f'Run ID: {mlflow.active_run().info.run_id}')

# Track experiments
mlflow ui  # Visit http://localhost:5000
```

---

## Model Deployment

### Docker

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY models/ models/
COPY app.py .

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-model
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ml-model
  template:
    metadata:
      labels:
        app: ml-model
    spec:
      containers:
      - name: ml-model
        image: myregistry/ml-model:v1
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: ml-model-service
spec:
  selector:
    app: ml-model
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer
```

---

## Monitoring

```python
from prometheus_client import Counter, Histogram, make_asgi_app

# Metrics
prediction_counter = Counter('predictions_total', 'Total predictions made')
prediction_latency = Histogram('prediction_latency_seconds', 'Prediction latency')

@app.post('/predict')
async def predict(input_data: PredictionInput):
    with prediction_latency.time():
        result = model.predict(...)
        prediction_counter.inc()
        return result

# Add Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)
```

---

## Best Practices

- Version models and data
- Track experiments (MLflow, Weights & Biases)
- Validate data before training
- Monitor model performance in production
- Retrain regularly with new data
- A/B test new models
- Set up alerts for model drift
- Use feature stores for consistency

---

**Remember**: ML in production is 10% training, 90% infrastructure. Build pipelines that scale.

**Created**: 2026-02-04
**Maintained By**: Google AI Researcher
