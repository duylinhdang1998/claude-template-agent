# Video Encoding - Netflix Per-Title Approach

Netflix's revolutionary encoding pipeline.

## Multi-Bitrate Encoding Ladder

```bash
# Netflix-style encoding with FFmpeg

# 4K encode (AV1) - Premium tier
ffmpeg -i input.mov \
  -c:v libsvtav1 \
  -crf 28 \
  -preset 6 \
  -g 240 \
  -pix_fmt yuv420p10le \
  -s 3840x2160 \
  -b:v 16M \
  -maxrate 20M \
  -bufsize 40M \
  -c:a libopus -b:a 256k \
  output_4k.mp4

# 1080p encode
ffmpeg -i input.mov \
  -c:v libx264 \
  -preset slow \
  -crf 23 \
  -s 1920x1080 \
  -b:v 5M \
  -maxrate 7M \
  -bufsize 14M \
  -c:a aac -b:a 192k \
  output_1080p.mp4

# 720p encode
ffmpeg -i input.mov \
  -c:v libx264 \
  -preset slow \
  -crf 23 \
  -s 1280x720 \
  -b:v 2.5M \
  -maxrate 3.5M \
  -bufsize 7M \
  -c:a aac -b:a 128k \
  output_720p.mp4

# 480p encode
ffmpeg -i input.mov \
  -c:v libx264 \
  -preset slow \
  -crf 23 \
  -s 854x480 \
  -b:v 1M \
  -maxrate 1.5M \
  -bufsize 3M \
  -c:a aac -b:a 96k \
  output_480p.mp4
```

## Per-Title Encoding

Netflix analyzes each video and optimizes bitrate ladder:

**Traditional Encoding** (same bitrates for all videos):
```
4K:    16 Mbps
1080p: 5 Mbps
720p:  2.5 Mbps
480p:  1 Mbps
```

**Per-Title Encoding** (optimized per video):
```
Action movie (complex):
  4K:    18 Mbps (needs more)
  1080p: 6 Mbps
  720p:  3 Mbps

Simple animation (less complex):
  4K:    12 Mbps (needs less, save bandwidth!)
  1080p: 4 Mbps
  720p:  2 Mbps
```

**Result**: 20-30% bandwidth savings without quality loss.

## Encoding Pipeline

```python
# Netflix-style encoding pipeline

import subprocess

def encode_video(input_file, title_id):
    """
    Encode video with per-title optimization
    """
    # 1. Analyze video complexity
    complexity = analyze_complexity(input_file)

    # 2. Determine optimal bitrate ladder
    bitrates = optimize_bitrate_ladder(complexity)

    # 3. Encode all variants
    outputs = []
    for resolution, bitrate in bitrates.items():
        output = encode_variant(
            input_file,
            resolution,
            bitrate,
            codec='libx264'  # or AV1 for premium
        )
        outputs.append(output)

    # 4. Generate HLS manifests
    create_hls_manifests(outputs, title_id)

    return outputs

def analyze_complexity(input_file):
    """
    Analyze video complexity using spatial/temporal information
    """
    # Use ffmpeg to analyze
    result = subprocess.run([
        'ffmpeg', '-i', input_file,
        '-vf', 'scale=1280:720',
        '-f', 'null', '-'
    ], capture_output=True, text=True)

    # Parse complexity metrics
    # High motion = higher bitrate needed
    # Low motion = lower bitrate OK
    return calculate_complexity_score(result.stderr)
```

## Codec Comparison

| Codec | Compression | CPU Cost | Browser Support |
|-------|-------------|----------|----------------|
| **H.264 (AVC)** | Baseline | Low | 100% |
| **H.265 (HEVC)** | 50% better | Medium | 80% |
| **VP9** | 40% better | Medium | 90% |
| **AV1** | 30% better than HEVC | High | 70% |

Netflix strategy:
- H.264: All devices
- HEVC: Premium devices (iPhone, smart TVs)
- AV1: Future (gradual rollout)
