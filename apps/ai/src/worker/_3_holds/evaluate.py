# @date 2026-11-24
# @file evaluate.py
# @brief Accuracy of the hold colour names on a labelled dataset (built by apps/ai/training/holds).
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Colour name accuracy on ground-truth hold masks.

The dataset is the output of ``holds merge`` (apps/ai/training/holds): YOLO segmentation labels in
``labels/<split>/`` and the original class of every instance in ``meta.json``. Only instances
whose original class is a colour (``<colour>_hold``, as in the Guillaume dataset) are scored.
"""

import json
from collections import Counter
from pathlib import Path

import cv2
import numpy as np

from worker._3_holds._2_hold_color import PALETTE, hold_colors


def _polygons(label_file: Path, width: int, height: int) -> list[np.ndarray]:
    lines = label_file.read_text(encoding="utf-8").splitlines()
    return [np.array(line.split()[1:], dtype=np.float64).reshape(-1, 2) * [width, height] for line in lines]


def evaluate_colors(dataset_dir: str | Path, splits: tuple[str, ...] = ("val", "test")) -> dict:
    """Return the overall accuracy, the accuracy per colour and the most frequent confusions."""
    dataset_dir = Path(dataset_dir)
    meta = json.loads((dataset_dir / "meta.json").read_text(encoding="utf-8"))
    total, correct, confusions = Counter(), Counter(), Counter()
    for key, entry in meta.items():
        truths = [name.removesuffix("_hold") for name in entry["instances"]]
        if key.split("/")[0] not in splits or not any(t in PALETTE for t in truths):
            continue
        image = cv2.imread(str(dataset_dir / "images" / key))
        height, width = image.shape[:2]
        polygons = _polygons((dataset_dir / "labels" / key).with_suffix(".txt"), width, height)
        for truth, color in zip(truths, hold_colors(image, polygons)):
            if truth not in PALETTE or color is None:
                continue
            total[truth] += 1
            correct[truth] += color.name == truth
            if color.name != truth:
                confusions[(truth, color.name)] += 1
    return {
        "accuracy": sum(correct.values()) / max(1, sum(total.values())),
        "holds": sum(total.values()),
        "per_color": {name: (correct[name] / total[name], total[name]) for name in sorted(total)},
        "confusions": confusions.most_common(5),
    }
