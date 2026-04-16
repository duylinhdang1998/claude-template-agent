# Transformers - Google's Innovation

Attention mechanism that revolutionized NLP.

## Architecture

```python
import tensorflow as tf

# Multi-head attention (core of Transformer)
class MultiHeadAttention(tf.keras.layers.Layer):
    def __init__(self, d_model, num_heads):
        super().__init__()
        self.num_heads = num_heads
        self.d_model = d_model
        self.depth = d_model // num_heads

        self.wq = tf.keras.layers.Dense(d_model)
        self.wk = tf.keras.layers.Dense(d_model)
        self.wv = tf.keras.layers.Dense(d_model)
        self.dense = tf.keras.layers.Dense(d_model)

    def split_heads(self, x, batch_size):
        x = tf.reshape(x, (batch_size, -1, self.num_heads, self.depth))
        return tf.transpose(x, perm=[0, 2, 1, 3])

    def call(self, v, k, q, mask=None):
        batch_size = tf.shape(q)[0]

        q = self.wq(q)
        k = self.wk(k)
        v = self.wv(v)

        q = self.split_heads(q, batch_size)
        k = self.split_heads(k, batch_size)
        v = self.split_heads(v, batch_size)

        # Scaled dot-product attention
        matmul_qk = tf.matmul(q, k, transpose_b=True)
        dk = tf.cast(tf.shape(k)[-1], tf.float32)
        scaled_attention_logits = matmul_qk / tf.math.sqrt(dk)

        if mask is not None:
            scaled_attention_logits += (mask * -1e9)

        attention_weights = tf.nn.softmax(scaled_attention_logits, axis=-1)
        output = tf.matmul(attention_weights, v)

        output = tf.transpose(output, perm=[0, 2, 1, 3])
        output = tf.reshape(output, (batch_size, -1, self.d_model))

        return self.dense(output)
```

## BERT (Bidirectional Encoder Representations from Transformers)

Fine-tuning BERT for classification:

```python
from transformers import BertTokenizer, TFBertForSequenceClassification
import tensorflow as tf

# Load pre-trained BERT
tokenizer = BertTokenizer.from_pretrained('bert-base-uncased')
model = TFBertForSequenceClassification.from_pretrained(
    'bert-base-uncased',
    num_labels=2
)

# Prepare data
def encode_examples(examples):
    return tokenizer(
        examples['text'],
        truncation=True,
        padding='max_length',
        max_length=128,
        return_tensors='tf'
    )

# Fine-tune
optimizer = tf.keras.optimizers.Adam(learning_rate=2e-5)
model.compile(
    optimizer=optimizer,
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=['accuracy']
)

model.fit(train_dataset, validation_data=val_dataset, epochs=3)
```

## Vision Transformer (ViT)

Transformers for images:

```python
from transformers import ViTImageProcessor, TFViTForImageClassification
from PIL import Image

# Load pre-trained ViT
processor = ViTImageProcessor.from_pretrained('google/vit-base-patch16-224')
model = TFViTForImageClassification.from_pretrained('google/vit-base-patch16-224')

# Classify image
image = Image.open('cat.jpg')
inputs = processor(images=image, return_tensors='tf')
outputs = model(**inputs)
logits = outputs.logits

predicted_class = logits.argmax(-1).numpy()[0]
print(f"Predicted class: {model.config.id2label[predicted_class]}")
```

## Best Practices

1. **Start with pre-trained** - BERT, T5, ViT
2. **Fine-tune, don't train from scratch** - Transfer learning
3. **Use appropriate model size** - base vs large vs XL
4. **Tokenization matters** - WordPiece, SentencePiece
5. **Monitor attention weights** - Understand what model learns
