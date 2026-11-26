# @date 2026-11-17
# @file merge.py
# @brief File description.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Merge Roboflow YOLO-seg exports into a single `hold` / `volume` dataset.

Roboflow exports augment each training image several times (files named
`<source>_jpg.rf.<hash>.jpg`). Those variants are collapsed back to one image per
source photo, then every source is re-split into train/val/test without leaking
variants of the same photo across splits.

Every source class is mapped onto the classes of `configs/holds.yaml`
(`volume` -> volume, `tape` -> dropped, anything else -> hold). The original class
name of each kept instance is recorded in `meta.json`, so that colour labels can
later serve as ground truth for the dominant-colour step (B3).
"""

from __future__ import annotations

import json
import random
import re
import shutil
from dataclasses import dataclass, field
from pathlib import Path

import cv2
import numpy as np
import yaml

SPLITS = ("train", "val", "test")
ROBOFLOW_SPLITS = {"train": "train", "valid": "val", "test": "test"}
DROPPED_CLASSES = {"tape"}
VOLUME_CLASSES = {"volume"}
IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
NOISE_THRESHOLD = (
    0.01  # fraction of saturated pixels above which salt & pepper noise is assumed
)


@dataclass
class Variant:
    """One image file of a Roboflow export and its label file."""

    image: Path
    label: Path
    split: str


@dataclass
class SourceImage:
    """All exported variants of a single original photo."""

    source: str
    key: str
    variants: list[Variant] = field(default_factory=list)


def target_class(name: str, names: dict[int, str]) -> int | None:
    """Map a source class name onto a target class id (`None` drops the instance)."""
    lowered = name.lower()
    if lowered in DROPPED_CLASSES:
        return None
    by_name = {v: k for k, v in names.items()}
    return by_name["volume"] if lowered in VOLUME_CLASSES else by_name["hold"]


def variant_key(filename: str) -> str:
    """Return the original photo name shared by all Roboflow variants of an image."""
    return re.sub(r"\.rf\.[0-9a-f]+$", "", Path(filename).stem)


def read_source_names(source_dir: Path) -> list[str]:
    """Read the class names of a Roboflow export from its `data.yaml`."""
    data = yaml.safe_load((source_dir / "data.yaml").read_text(encoding="utf-8"))
    names = data["names"]
    return list(names.values()) if isinstance(names, dict) else list(names)


def collect_source(source_dir: Path) -> list[SourceImage]:
    """Group the images of a Roboflow export by original photo."""
    groups: dict[str, SourceImage] = {}
    for rf_split, split in ROBOFLOW_SPLITS.items():
        image_dir = source_dir / rf_split / "images"
        if not image_dir.is_dir():
            continue
        for image in sorted(image_dir.iterdir()):
            if image.suffix.lower() not in IMAGE_SUFFIXES:
                continue
            label = source_dir / rf_split / "labels" / f"{image.stem}.txt"
            key = variant_key(image.name)
            group = groups.setdefault(key, SourceImage(source=source_dir.name, key=key))
            group.variants.append(Variant(image=image, label=label, split=split))
    return list(groups.values())


def noise_ratio(gray: np.ndarray) -> float:
    """Fraction of fully black or white pixels, a cheap salt & pepper noise estimate."""
    return float(((gray == 0) | (gray == 255)).mean())


def pick_variant(group: SourceImage) -> tuple[Variant, float]:
    """Pick the cleanest variant: least noise and brightness closest to the group median.

    Returns the chosen variant and its noise ratio.
    """
    if len(group.variants) == 1:
        gray = cv2.imread(str(group.variants[0].image), cv2.IMREAD_GRAYSCALE)
        return group.variants[0], noise_ratio(gray)
    stats = []
    for variant in group.variants:
        gray = cv2.imread(str(variant.image), cv2.IMREAD_GRAYSCALE)
        stats.append((noise_ratio(gray), float(gray.mean())))
    median = float(np.median([brightness for _, brightness in stats]))
    scores = [noise + abs(brightness - median) / 255 for noise, brightness in stats]
    best = int(np.argmin(scores))
    return group.variants[best], stats[best][0]


def split_groups(
    groups: list[SourceImage], ratios: tuple[float, float, float], seed: int
) -> dict[str, list[SourceImage]]:
    """Shuffle photos of one source and split them, keeping at least one per split."""
    shuffled = sorted(groups, key=lambda g: g.key)
    random.Random(seed).shuffle(shuffled)
    total = len(shuffled)
    n_test = max(1, round(total * ratios[2])) if total >= 3 else 0
    n_val = max(1, round(total * ratios[1])) if total >= 2 else 0
    return {
        "test": shuffled[:n_test],
        "val": shuffled[n_test : n_test + n_val],
        "train": shuffled[n_test + n_val :],
    }


def remap_labels(
    lines: list[str], source_names: list[str], names: dict[int, str]
) -> tuple[list[str], list[str]]:
    """Remap YOLO label lines; return the new lines and the source class of each kept line.

    Coordinates are clipped to [0, 1]: Roboflow's shear augmentation can push polygon
    points slightly outside the image, which makes ultralytics drop the whole image.
    """
    remapped, origins = [], []
    for line in lines:
        parts = line.split()
        if not parts:
            continue
        source_name = source_names[int(parts[0])]
        target = target_class(source_name, names)
        if target is None:
            continue
        coords = [f"{min(max(float(v), 0.0), 1.0):.6g}" for v in parts[1:]]
        remapped.append(" ".join([str(target), *coords]))
        origins.append(source_name)
    return remapped, origins


def write_image(src: Path, dst: Path, max_side: int, denoise: bool) -> tuple[int, int]:
    """Copy an image, optionally removing salt & pepper noise and downscaling it."""
    image = cv2.imread(str(src))
    if denoise:
        image = cv2.medianBlur(image, 3)
    height, width = image.shape[:2]
    scale = max_side / max(height, width)
    if scale < 1:
        image = cv2.resize(
            image,
            (round(width * scale), round(height * scale)),
            interpolation=cv2.INTER_AREA,
        )
    cv2.imwrite(str(dst.with_suffix(".jpg")), image, [cv2.IMWRITE_JPEG_QUALITY, 95])
    return image.shape[1], image.shape[0]


def merge(
    sources: list[Path],
    out_dir: Path,
    config: Path,
    ratios: tuple[float, float, float] = (0.8, 0.15, 0.05),
    max_side: int = 1600,
    seed: int = 0,
) -> dict[str, int]:
    """Merge Roboflow exports into `out_dir` and write its `data.yaml` and `meta.json`.

    Returns the number of images written per split.
    """
    names = yaml.safe_load(config.read_text(encoding="utf-8"))["names"]
    if out_dir.exists():
        shutil.rmtree(out_dir)
    for split in SPLITS:
        (out_dir / "images" / split).mkdir(parents=True)
        (out_dir / "labels" / split).mkdir(parents=True)

    meta: dict[str, dict] = {}
    counts = dict.fromkeys(SPLITS, 0)
    for source_dir in sources:
        source_names = read_source_names(source_dir)
        for split, groups in split_groups(
            collect_source(source_dir), ratios, seed
        ).items():
            for group in groups:
                variant, noise = pick_variant(group)
                augmented = (
                    variant.split == "train"
                )  # Roboflow only augments its train split
                denoise = augmented and noise > NOISE_THRESHOLD
                name = f"{group.source}_{re.sub(r'[^A-Za-z0-9_-]', '_', group.key)}"
                lines = (
                    variant.label.read_text(encoding="utf-8").splitlines()
                    if variant.label.exists()
                    else []
                )
                labels, origins = remap_labels(lines, source_names, names)
                width, height = write_image(
                    variant.image, out_dir / "images" / split / name, max_side, denoise
                )
                (out_dir / "labels" / split / f"{name}.txt").write_text(
                    "\n".join(labels) + ("\n" if labels else ""), encoding="utf-8"
                )
                meta[f"{split}/{name}.jpg"] = {
                    "source": group.source,
                    "source_file": variant.image.name,
                    "source_split": variant.split,
                    "augmented": augmented,
                    "denoised": denoise,
                    "size": [width, height],
                    "instances": origins,
                }
                counts[split] += 1

    data = {
        "path": str(out_dir.resolve()),
        **{split: f"images/{split}" for split in SPLITS},
        "names": names,
    }
    (out_dir / "data.yaml").write_text(
        yaml.safe_dump(data, sort_keys=False), encoding="utf-8"
    )
    (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return counts
