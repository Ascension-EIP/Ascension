# holds

:::warning
**Version:** 0.2
:::

Training tool of the hold detection model (pipeline block B), based on Ultralytics YOLO26-seg: dataset merge, training, evaluation and export.

The detection itself runs in the AI worker ([apps/ai](../../README.md), step `_3_holds`), on the ONNX model written by `export`. The worker needs neither PyTorch nor Ultralytics, which stay in this project.

This project lives in `apps/ai/training/holds` but keeps its own `pyproject.toml` and environment: the worker's tests, lint and Docker image ignore `training/`. The moon project is still `holds` (`moon run holds:<task>`).

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
moon run holds:export   # runs/holds/weights/best.pt -> apps/ai/resources/holds_seg.onnx
```

Training outputs go to `runs/holds/`, predictions to `runs/predict/`.

Detection uses a confidence threshold of 0.10 by default: small footholds are found far more often (recall on holds under 25 px goes from 0.47 at 0.25 to 0.66), and the user validates holds anyway.

---

## Updating the model of the worker

1. Train (`moon run holds:train`) and check the masks mAP of `runs/holds/` on the test split.
2. Export: `moon run holds:export` writes `apps/ai/resources/holds_seg.onnx`. It keeps the standard head, and the worker applies the NMS itself: the end-to-end head finds fewer holds (recall 0.63 against 0.70 on the test split).
3. Check it in the worker: `cd ../.. && uv run worker holds-detect --image path/to/wall.jpg --out /tmp/holds.json --render /tmp/holds.jpg`.
4. Commit the new `holds_seg.onnx` with the worker: it is versioned like the MediaPipe models, so the Docker image always contains it.

The hold colours (step B3) are computed by the worker too (`apps/ai/src/worker/_3_holds/_2_hold_color.py`). Their accuracy is measured on the merged dataset of this project with `uv run worker holds-colors-eval --dataset training/holds/datasets/holds` from `apps/ai`.
