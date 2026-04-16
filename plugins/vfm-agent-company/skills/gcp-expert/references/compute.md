# GCP Compute Services

## Google Kubernetes Engine (GKE)

Production GKE cluster with best practices:

```yaml
# Terraform - Production GKE
resource "google_container_cluster" "primary" {
  name     = "production-cluster"
  location = "us-central1"  # Regional for HA

  # Multi-zone redundancy
  node_locations = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c"
  ]

  # Release channel for auto-upgrades
  release_channel {
    channel = "REGULAR"
  }

  # Workload Identity (Google best practice)
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  # Managed Prometheus monitoring
  monitoring_config {
    managed_prometheus {
      enabled = true
    }
  }
}
```

## Cloud Run (Serverless Containers)

Deploy container to Cloud Run:

```bash
gcloud run deploy api-service \
  --image gcr.io/project/api:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 100 \
  --cpu 2 \
  --memory 4Gi \
  --concurrency 80
```

## Compute Engine (VMs)

Create optimized VM instance:

```bash
gcloud compute instances create app-server \
  --machine-type n2-standard-4 \
  --image-family ubuntu-2204-lts \
  --image-project ubuntu-os-cloud \
  --boot-disk-size 100GB \
  --boot-disk-type pd-ssd \
  --network-tier PREMIUM \
  --maintenance-policy MIGRATE \
  --scopes cloud-platform
```

## When to Use What

- **GKE**: Complex microservices, need Kubernetes orchestration
- **Cloud Run**: Simple containerized services, serverless, auto-scale
- **Compute Engine**: Legacy apps, specific OS requirements, custom configs
