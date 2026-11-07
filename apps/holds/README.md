# holds

:::warning
**Version:** 0.1
:::

Climbing hold detection and route reading (pipeline block B), based on Ultralytics YOLO26-seg.

---

## Setup

```bash
moon run holds:setup    # download yolo26n-seg / yolo26s-seg into models/
moon run holds:install  # uv sync
moon run holds:check    # verify torch / CUDA
```

---

## Dataset

Place a YOLO-format segmentation dataset in `datasets/holds/`:

```
datasets/holds/
├── images/{train,val,test}/
└── labels/{train,val,test}/
```

Classes are defined in `configs/holds.yaml` (`hold`, `volume`).

---

## Usage

```bash
uv run python -m holds train --model yolo26s-seg.pt --imgsz 1280 --epochs 100
uv run python -m holds predict path/to/wall.jpg
```

Training outputs go to `runs/holds/`, predictions to `runs/predict/`.
