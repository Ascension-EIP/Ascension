# @date 2026-11-17
# @file test_merge.py
# @brief File description.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Tests for merging Roboflow exports into the hold/volume dataset."""

import json
from pathlib import Path

import cv2
import numpy as np
import yaml

from holds.merge import (
    collect_source,
    merge,
    pick_variant,
    remap_labels,
    split_groups,
    variant_key,
)

NAMES = {0: "hold", 1: "volume"}
POLYGON = "0.1 0.1 0.2 0.1 0.2 0.2"


def make_export(
    root: Path, names: list[str], images: dict[str, list[tuple[str, int, str]]]
) -> Path:
    """Create a fake Roboflow export: {split: [(filename, brightness, label_text)]}."""
    root.mkdir(parents=True)
    (root / "data.yaml").write_text(yaml.safe_dump({"names": names}), encoding="utf-8")
    for split, files in images.items():
        (root / split / "images").mkdir(parents=True)
        (root / split / "labels").mkdir(parents=True)
        for filename, brightness, label in files:
            cv2.imwrite(
                str(root / split / "images" / filename),
                np.full((40, 30, 3), brightness, np.uint8),
            )
            (root / split / "labels" / f"{Path(filename).stem}.txt").write_text(
                label, encoding="utf-8"
            )
    return root


def write_config(tmp_path: Path) -> Path:
    config = tmp_path / "holds.yaml"
    config.write_text(yaml.safe_dump({"names": NAMES}), encoding="utf-8")
    return config


def test_remap_labels_clips_out_of_bounds_points():
    labels, _ = remap_labels(["0 1.0236757 0.5 -0.01 0.2 0.3 0.4"], ["hold"], NAMES)
    assert labels == ["0 1 0.5 0 0.2 0.3 0.4"]


def test_variant_key_strips_roboflow_suffix():
    assert variant_key("IMG_01_jpg.rf.941a74e1e044216e.jpg") == "IMG_01_jpg"
    assert variant_key("plain.jpg") == "plain"


def test_remap_labels_maps_volume_drops_tape_and_keeps_origin():
    source_names = ["crimp", "tape", "volume"]
    lines = [f"0 {POLYGON}", f"1 {POLYGON}", f"2 {POLYGON}", ""]
    labels, origins = remap_labels(lines, source_names, NAMES)
    assert labels == [f"0 {POLYGON}", f"1 {POLYGON}"]
    assert origins == ["crimp", "volume"]


def test_pick_variant_avoids_brightness_outlier(tmp_path):
    export = make_export(
        tmp_path / "src",
        ["hold"],
        {
            "train": [
                (f"a_jpg.rf.{h}.jpg", b, "")
                for h, b in (("aa", 100), ("bb", 110), ("cc", 20))
            ]
        },
    )
    (group,) = collect_source(export)
    assert len(group.variants) == 3
    chosen, _ = pick_variant(group)
    assert (
        chosen.image.name == "a_jpg.rf.aa.jpg"
    )  # median brightness, the dark outlier is skipped


def test_split_groups_is_deterministic_and_disjoint(tmp_path):
    export = make_export(
        tmp_path / "src",
        ["hold"],
        {"train": [(f"p{i}.jpg", 100, "") for i in range(20)]},
    )
    groups = collect_source(export)
    first = split_groups(groups, (0.8, 0.15, 0.05), seed=0)
    second = split_groups(groups, (0.8, 0.15, 0.05), seed=0)
    keys = {split: [g.key for g in gs] for split, gs in first.items()}
    assert keys == {split: [g.key for g in gs] for split, gs in second.items()}
    assert (len(keys["train"]), len(keys["val"]), len(keys["test"])) == (16, 3, 1)
    assert len({key for split_keys in keys.values() for key in split_keys}) == 20


def test_merge_writes_dataset_meta_and_config(tmp_path):
    datasets = tmp_path / "datasets"
    source = make_export(
        datasets / "gym",
        ["red_hold", "tape", "volume"],
        {
            "train": [
                (f"p{i}_jpg.rf.{h}.jpg", 100, f"0 {POLYGON}\n1 {POLYGON}\n")
                for i in range(8)
                for h in ("a1", "b2")
            ],
            "valid": [("v_jpg.rf.c3.jpg", 100, f"2 {POLYGON}\n")],
        },
    )
    out = datasets / "holds"
    counts = merge([source], out, write_config(tmp_path), max_side=20)

    assert sum(counts.values()) == 9  # 8 train photos (2 variants each) + 1 valid photo
    assert all(counts[split] >= 1 for split in ("train", "val", "test"))

    data = yaml.safe_load((out / "data.yaml").read_text(encoding="utf-8"))
    assert Path(data["path"]) == out.resolve()
    assert data["names"] == NAMES

    meta = json.loads((out / "meta.json").read_text(encoding="utf-8"))
    assert len(meta) == 9
    entry = next(v for v in meta.values() if v["source_file"].startswith("v_jpg"))
    assert entry["instances"] == ["volume"]
    assert entry["augmented"] is False

    image_path = (
        out
        / "images"
        / next(k for k in meta if meta[k]["source_file"].startswith("p0_"))
    )
    assert max(cv2.imread(str(image_path)).shape[:2]) == 20
    label = (
        out / "labels" / image_path.parent.name / f"{image_path.stem}.txt"
    ).read_text(encoding="utf-8")
    assert label == f"0 {POLYGON}\n"  # tape dropped, red_hold -> hold
