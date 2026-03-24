# Training at Scale - Google TPU

Train large models on Google's TPU infrastructure.

## TPU Basics

**TPU** (Tensor Processing Unit): Google's custom AI chip
- v4: 275 TFLOPS, optimized for training
- v5: 459 TFLOPS, latest generation
- Pods: Up to thousands of TPU chips

## Training on TPU

```python
import tensorflow as tf

# TPU initialization
resolver = tf.distribute.cluster_resolver.TPUClusterResolver()
tf.config.experimental_connect_to_cluster(resolver)
tf.tpu.experimental.initialize_tpu_system(resolver)

strategy = tf.distribute.TPUStrategy(resolver)

# Model creation inside strategy scope
with strategy.scope():
    model = create_model()

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
        metrics=['accuracy']
    )

# Train
model.fit(
    train_dataset,
    epochs=10,
    validation_data=val_dataset
)
```

## Distributed Training Strategies

### Data Parallelism

Replicate model on multiple devices, split data:

```python
# Multi-GPU/TPU data parallelism
strategy = tf.distribute.MultiWorkerMirroredStrategy()

with strategy.scope():
    model = create_model()

# Each worker processes different batch
# Gradients averaged across workers
```

### Model Parallelism

Split model across devices (for very large models):

```python
# Example: Split layers across TPUs
with tf.device('/job:worker/task:0/device:TPU:0'):
    layer1 = tf.keras.layers.Dense(1024, activation='relu')

with tf.device('/job:worker/task:0/device:TPU:1'):
    layer2 = tf.keras.layers.Dense(1024, activation='relu')

# Each device handles subset of layers
```

## Mixed Precision Training

Use bfloat16 for faster training:

```python
# Enable mixed precision
policy = tf.keras.mixed_precision.Policy('mixed_bfloat16')
tf.keras.mixed_precision.set_global_policy(policy)

# Model automatically uses bfloat16 for computations
# Maintains float32 for numerical stability where needed
```

## Gradient Accumulation

Train with larger effective batch size:

```python
# Accumulate gradients over N steps
accumulation_steps = 4
accumulated_gradients = [tf.Variable(tf.zeros_like(var), trainable=False)
                         for var in model.trainable_variables]

for step, (x, y) in enumerate(train_dataset):
    with tf.GradientTape() as tape:
        predictions = model(x, training=True)
        loss = loss_fn(y, predictions) / accumulation_steps

    gradients = tape.gradient(loss, model.trainable_variables)

    # Accumulate
    for i, grad in enumerate(gradients):
        accumulated_gradients[i].assign_add(grad)

    if (step + 1) % accumulation_steps == 0:
        # Apply accumulated gradients
        optimizer.apply_gradients(zip(accumulated_gradients, model.trainable_variables))

        # Reset
        for grad in accumulated_gradients:
            grad.assign(tf.zeros_like(grad))
```

## Best Practices

1. **Use TPU pods for large models** - Cost-effective at scale
2. **Optimize data pipeline** - Use tf.data, prefetch
3. **Mixed precision** - bfloat16 for 2x speedup
4. **Monitor utilization** - TensorBoard profiler
5. **Checkpointing** - Save frequently for long training
