<p align="center">
  <h1 align="center">ALICE</h1>
  <p align="center"><b>A</b>nalyse · <b>L</b>earn · <b>I</b>ngest · <b>C</b>urate · <b>E</b>xport</p>
  <p align="center">All-in-one AI-powered image annotation, training, and dataset management toolkit.</p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/python-3.8+-blue?logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/YOLO-v8%20%7C%2011-orange" alt="YOLO">
  <img src="https://img.shields.io/badge/Frigate-NVR-green" alt="Frigate">
  <img src="https://img.shields.io/badge/license-CC%20BY--NC%204.0-lightgrey" alt="License">
</p>

---

## Why?

I needed a tool to train a YOLO model for my cameras, using my own images, with the specific angles and scenarios around my house.
I couldn't find anything on the internet (or if it existed, I was probably too drunk to find it), so I built my own utility to fit my needs.
If you find it useful — enjoy. If not, well... cry me a river! :)

## Quick Start

```bash
# Build and set up virtual environment
python3 builder.py

# Run
./alice.py
```

The builder assembles `alice.py` from source modules, creates a `.venv` with base dependencies, and patches the shebang so `./alice.py` uses the venv automatically.

On first run, `alice.conf` is generated with sensible defaults. Models and datasets directories are created next to `alice.py`. Open **http://localhost:8080** and you're ready to go — download a YOLO model from Settings, configure your Frigate paths if needed, and start working.

```bash
# Options
./alice.py --port 9090                  # custom port
./alice.py --conf /path/to/alice.conf   # custom config path
```

### Docker

```bash
docker compose up -d
```

Edit `docker-compose.yml` to map your Frigate media, datasets, and models directories. See [Docker Setup](#docker-setup) below.

## Features

### Viewer — Dataset Mode
Browse and annotate YOLO bounding boxes with a full canvas editor — draw, resize, move, delete, undo. Filter by split (train / val / empty) or by class. Gallery grid view, keyboard shortcuts, right-click context menus.

### Viewer — Live Mode
Browse Frigate NVR event snapshots in real-time. Filter by camera and time window. Transfer snapshots directly into your training dataset with automatic WebP → JPG conversion.

### Viewer — Video Mode
Frame-by-frame analysis of Frigate video exports. Seekbar, step controls, adjustable playback FPS. Automated frame scanner with AI detection for batch export.

### AI Analysis
Run YOLO inference on any image across all three modes. Merge detected boxes into annotations (dedup by IoU > 0.5). Preview mode shows detections without saving. Live detection auto-runs as you navigate.

### Duplicate Detection
Perceptual hashing (pHash) with DCT-based 64-bit hashes. Multiprocessing-accelerated computation. Side-by-side comparison. Box-similarity dedup per camera. NMS cleanup for overlapping same-class boxes.

### Training Pipeline

Five-step pipeline — each step toggleable, runnable individually or as a sequence:

| Step | What it does |
|------|-------------|
| **1. Export** | Extract snapshots from Frigate SQLite DB → 90/10 train/val split |
| **2. Dedup** | Remove duplicates via pHash, box similarity, and NMS cleanup |
| **3. Annotate** | Auto-label all images using a teacher model |
| **4. Train** | Fine-tune student model with real-time metrics (loss, mAP50, mAP50-95) |
| **5. Export ONNX** | Convert to ONNX for deployment (FP16, dynamic batch) |

All steps log to the Logs tab with COMPLETED / FAILED / STOPPED status.

### Settings
All configuration in `alice.conf` — editable from the web UI or directly in the file. Built-in dependency checker with one-click install. Model downloader for YOLO11 and YOLOv8 variants.

## Requirements

Python 3.8+ required. The builder creates a `.venv` and installs the base dependency (Pillow) automatically. All other dependencies are optional and can be installed from the Settings page in the web UI with one click:

| Package | Purpose |
|---------|---------|
| **Pillow** | Image processing, pHash, format conversion (auto-installed by builder) |
| **ultralytics** | YOLO model training & inference |
| **opencv-python-headless** | Video frame extraction |
| **numpy** | Numerical operations for dedup |
| **inotify** | Filesystem watching on Linux (falls back to polling) |

> **Note:** ALICE does **not** install NVIDIA drivers or CUDA. If you want GPU-accelerated training and inference, install the [NVIDIA drivers](https://www.nvidia.com/Download/index.aspx) and [CUDA toolkit](https://developer.nvidia.com/cuda-toolkit) on your system before running ALICE.

## Docker Setup

```yaml
services:
  alice:
    build: .
    container_name: alice
    ports:
      - "8080:8080"
    volumes:
      - ./alice.conf:/app/alice.conf
      - /path/to/datasets:/datasets
      - /path/to/models:/models
      - /path/to/frigate/media/clips:/clips:ro
      - /path/to/frigate/media/exports:/exports:ro
      - /path/to/frigate/config/frigate.db:/frigate.db:ro
    restart: unless-stopped
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

> **Note:** The `deploy.resources` section requires [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host. Remove it if running CPU-only.

Edit the volume paths to match your setup, then:

```bash
docker compose up -d
```

Your `alice.conf` paths should reference the container-side mount points (`/datasets`, `/models`, `/clips`, `/exports`, `/frigate.db`).

## Dataset Structure

Alice expects standard YOLO format:

```
dataset/
├── images/
│   ├── train/*.jpg
│   └── val/*.jpg
├── labels/
│   ├── train/*.txt
│   └── val/*.txt
└── dataset.yaml          ← auto-generated by trainer
```

## Building from Source

Alice is developed as modular source files assembled into a single `alice.py`:

```bash
python3 builder.py                     # → alice.py + .venv/
python3 builder.py -o /path/to/out.py  # custom output path
python3 builder.py --no-venv           # skip venv creation
python3 builder.py --check             # verify all modules and assets exist
python3 builder.py --list              # show resolved dependency order
python3 builder.py --strict            # abort on name conflicts
```

The builder:
1. Reads the import graph from `from .module import` statements in each `src/*.py`
2. Topologically sorts modules by dependency order
3. Strips all relative imports (redundant in the flat monolith namespace)
4. Injects CSS, JS, and HTML assets from `src/assets/` into placeholder tokens
5. Writes a single self-contained `alice.py`
6. Creates a `.venv` with Pillow and patches the shebang

Re-running `builder.py` rebuilds `alice.py` but skips venv creation if `.venv` already exists.

Source modules live in `src/` — see [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `← →` | Navigate images |
| `D` | Delete selected box |
| `P` | Set to Person class |
| `A` | AI Analyse (save) |
| `M` | Copy/Move dialog |
| `E` | Toggle panel |
| `G` | Gallery view |
| `J` | Jump to image # |
| `Ctrl+Z` | Undo |
| `Ctrl+Scroll` | Zoom |
| `Space` | Play/pause (video) |

## License

[CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) — free for personal, non-commercial use. For commercial licensing, contact alice@it-link.net.

## Author

Simon Cirstoiu
