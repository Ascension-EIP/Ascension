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

Download Roboflow exports (format **YOLOv8** / **YOLO26**, segmentation) and unzip each one into its own folder under `datasets/` (for example `datasets/panclimb/`, `datasets/guillaume/`). Then merge them:

```bash
moon run holds:merge  # or: uv run python -m holds merge panclimb guillaume
```

The merge:

- maps every source class onto `configs/holds.yaml` (`volume` → `volume`, `tape` → dropped, anything else → `hold`);
- keeps one image per original photo (Roboflow augmented variants are collapsed, salt & pepper noise is removed);
- re-splits each source 80/15/5 into `train`, `val` and `test` with a fixed seed;
- clips polygon points to the image bounds and downscales images to 1600 px;
- writes `datasets/holds/data.yaml` (training config) and `datasets/holds/meta.json` (original class of every instance, such as the hold colour or type, used to evaluate the colour step).

---

## Usage

```bash
uv run python -m holds train --model yolo26s-seg.pt --imgsz 1024 --epochs 100
uv run python -m holds predict path/to/wall.jpg
```

Training outputs go to `runs/holds/`, predictions to `runs/predict/`.
