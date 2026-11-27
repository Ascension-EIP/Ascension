---
id: 2f53fa4e-ab2b-4b41-8d65-c54fb20a0f1e
---

:::warning
**Version:** 0.2
:::

---

# Hold detection

## What it does

It takes a photo of a climbing wall and returns the holds it finds: for each hold a polygon contour, a type (`unknown` or `volume`; grip types are not classified yet) and a dominant colour with a colour name. In the job version it also estimates the plane of the wall (see [Pathfinding](pathfinding.md)) and stores it on the route.

---

## How it works

```mermaid
flowchart LR
    P["route photo"] --> Seg["_1_hold_segment (ONNX)"] --> Col["_2_hold_color"] --> J["holds JSON"]
    P --> W["wall plane (job only)"]
```

*Summary: a segmentation model finds the holds, a second step names the colour of each, and the job also fits the wall plane from a depth map.*

Code in `apps/ai/src/worker/_3_holds/`:

1. `_1_hold_segment.py`: YOLO segmentation model exported to ONNX (`resources/holds_seg.onnx`, run by ONNX Runtime on the CPU, no PyTorch), non-maximum suppression, masks converted to polygons.
2. `_2_hold_color.py`: dominant colour of each mask and its name (`yellow`, `green`, ...). The `rgb` is reliable, the name is a hint.
3. `_0_hold_detect.py`: chains both steps. `evaluate.py` measures the colour accuracy (`holds-colors-eval`).

The job `holds.detect` is in `apps/ai/src/worker/handlers/hold_detect_request.py`. After the detection it calls the depth model and stores `routes.wall_plane`. This never fails the job: without the depth model the holds are stored and the wall plane stays empty.

---

## Models and algorithms

| Step | Technique | Learned model? |
| --- | --- | --- |
| `_1_hold_segment` | Instance segmentation, YOLO26-seg (Ultralytics) exported to ONNX | Yes, trained by the team |
| `_2_hold_color` | Colour statistics in the CIELAB space, nearest reference colour | No |
| Wall plane (job only) | Depth model, then a plane fit: see [Pathfinding](pathfinding.md) | Yes (depth), no (fit) |

**The segmentation model.** YOLO is a single-pass convolutional network: one look at the image gives every object. The `-seg` variant also gives the shape of each object, not only a box. The photo is resized to fit 1024 x 1024 (the ratio is kept, the rest is padded with grey 114, as at training time). The network predicts 21 504 candidates, on three grids of different scales so that small and large holds are both found. For each candidate it outputs a box, a score for each of the 2 classes (`hold` and `volume`) and 32 mask coefficients. A second output holds 32 small "prototype" masks shared by the whole image. The mask of a candidate is the sum of the prototypes weighted by its 32 coefficients, cut to its box and thresholded at 0.5. The candidates then go through non-maximum suppression (a candidate that overlaps a better one of the same class by more than 70 % is dropped), and each mask is turned into a polygon.

**Why ONNX.** The model is trained with PyTorch and Ultralytics in `apps/ai/training/holds` on datasets from Roboflow that are merged into one (`holds:merge`), then exported to ONNX (`holds:export`). The worker only needs ONNX Runtime on the CPU, so it installs neither PyTorch nor Ultralytics. The post-processing above is rewritten in numpy to give the same holds as the training tool.

**A low threshold on purpose.** The confidence threshold is 0.10. Small footholds score low, and the user checks the holds afterwards, so a false hold costs one tap to remove while a missed hold is lost.

**The colour is not learned.** Pixels of the mask are summarised in CIELAB, a colour space where lightness and colour are separate. The mask is shrunk so that the wall around the hold does not count, the colour is the median of the 10 % most saturated pixels (chalk washes colours out), the lightness is the 25th percentile (chalk is lighter than the hold), and the tint of the lighting is corrected with the wall around the holds. The result is named after the closest colour of a fixed palette. It was measured at about 83 % correct names in a gym that the palette was calibrated on, and about 60 % in a new gym (red and orange, green and yellow, chalked black and cream are mixed up). The `rgb` is reliable, the name is a hint.

**What to remember.** The model has two classes. It does not tell a crimp from a sloper, so `type` is only `unknown` or `volume`.

---

## Prerequisites

From the root of the repository:

1. Tools: `uv`, `moon`. Docker only for the job.
2. `cp .env.example .env`. Optional variable: `HOLDS_MODEL_PATH` (default `resources/holds_seg.onnx`).
3. `moon run ai:install`. The hold model `apps/ai/resources/holds_seg.onnx` (42 MB) is versioned in git: nothing to download. It is produced by `moon run holds:export` from the training tool `apps/ai/training/holds`, which you only need to retrain it.
4. For the wall plane in the job only: `moon run ai:setup` downloads the depth model (`moge-2-vits-normal.onnx`, 141 MB).

---

## Run it from the CLI

```bash
cd apps/ai
mkdir -p /tmp/ascension
uv run worker holds-detect --image resources/voie.jpg --out /tmp/ascension/holds.json --render /tmp/ascension/holds.jpg
```

It takes about 1 s and prints `Wrote /tmp/ascension/holds.json (39 holds)`. `holds.json` has `image_width`, `image_height` and `holds`; each hold has `confidence`, `contour`, `type` and `color` (`{name, rgb, distance}`). On `voie.jpg` the colours found are yellow (12), green (9), orange (5), blue (5), white (3), red (2), cream (2) and black (1). `holds.jpg` is the photo with each hold drawn in its colour. Options: `--conf` (default 0.10, the confidence threshold) and `--model` (another ONNX file).

`holds-colors-eval --dataset training/holds/datasets/holds` measures the accuracy of the colour names on a labelled dataset. **It does not run from a fresh clone**: the dataset is not in git. It must first be built with `moon run holds:merge` from Roboflow exports unzipped in `apps/ai/training/holds/datasets/` (see `apps/ai/training/holds/README.md`). Without it the command fails with `No such file or directory: 'training/holds/datasets/holds/meta.json'`. This page did not run it with a dataset.

---

## Run it as a job

The job `holds.detect` is on the queue `holds.detect`. Start the infrastructure and the worker as described in [Worker modules](readme.md). Then:

```bash
cd apps/ai
uv run python src/producer.py seed-route --image resources/voie.jpg
# prints route_id=..., object_key=...
uv run python src/producer.py holds --job-id <route_id> --object-key <object_key>
```

`seed-route` creates a test user and a `pending` route and uploads the photo. `holds` publishes `holds.detect.requested` (`job_id` is the route id). The producer sends no `gravity`, so the wall angle stays empty.

Where to read the result:

- `routes` (id = `route_id`): `status` (`started`, `running`, `success`, `failed`), `progress`, `error`, `image_width`, `image_height`, `wall_plane` (homography, angle, focal length, inlier ratio) and `wall_angle_deg`.
- `holds` (`route_id`): one row per hold with `source = 'ai'`, `contour`, `color`, `type`. A redelivered job replaces the AI holds that the user has not corrected.

The worker also publishes `holds.detect.status`.

---

## Tests

```bash
cd apps/ai
uv run pytest -p no:cacheprovider -m "not e2e and not integration" -q \
  tests/test_holds.py tests/test_hold_handler.py tests/functional/test_cli_holds.py
```

Expected: `35 passed` in a few seconds.
