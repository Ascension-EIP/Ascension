# @date 2026-11-17
# @file __main__.py
# @brief File description.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Hold detection CLI: check, merge, train, predict, colors."""

import argparse
from collections import Counter
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
MODELS_DIR = ROOT / "models"
RUNS_DIR = ROOT / "runs"


def check(_: argparse.Namespace) -> None:
    import torch
    import ultralytics

    print(f"ultralytics {ultralytics.__version__} | torch {torch.__version__}")
    if torch.cuda.is_available():
        print(f"CUDA OK: {torch.cuda.get_device_name(0)}")
    else:
        print("CUDA not available, running on CPU")


def merge(args: argparse.Namespace) -> None:
    from holds.merge import merge as merge_datasets

    counts = merge_datasets(
        sources=[ROOT / "datasets" / name for name in args.sources],
        out_dir=ROOT / args.out,
        config=ROOT / args.config,
        max_side=args.max_side,
        seed=args.seed,
    )
    print(f"Merged {sum(counts.values())} images into {args.out}: {counts}")


def train(args: argparse.Namespace) -> None:
    from ultralytics import YOLO

    model = YOLO(MODELS_DIR / args.model)
    model.train(
        data=str(ROOT / args.data),
        imgsz=args.imgsz,
        epochs=args.epochs,
        batch=args.batch,
        project=str(RUNS_DIR),
        name=args.name,
    )


def predict(args: argparse.Namespace) -> None:
    from ultralytics import YOLO

    model = YOLO(args.weights)
    model.predict(
        source=args.source,
        imgsz=args.imgsz,
        conf=args.conf,
        save=True,
        project=str(RUNS_DIR),
        name="predict",
    )


def colors(args: argparse.Namespace) -> None:
    import json

    import cv2
    from ultralytics import YOLO

    from holds.colors import Palette, draw, image_colors

    palette = Palette.load(ROOT / args.palette)
    model = YOLO(args.weights)
    out_dir = RUNS_DIR / "colors"
    out_dir.mkdir(parents=True, exist_ok=True)
    for result in model.predict(
        source=args.source, imgsz=args.imgsz, conf=args.conf, stream=True, verbose=False
    ):
        image = result.orig_img
        polygons = [] if result.masks is None else list(result.masks.xy)
        hold_colors = image_colors(image, polygons, palette)
        holds = []
        for i, (polygon, color) in enumerate(zip(polygons, hold_colors)):
            if color is None:
                continue
            holds.append(
                {
                    "id": i,
                    "class": result.names[int(result.boxes.cls[i])],
                    "confidence": round(float(result.boxes.conf[i]), 3),
                    "polygon": np.round(polygon.astype(float), 1).tolist(),
                    "color": {
                        "name": color.name,
                        "distance": color.distance,
                        "rgb": list(color.rgb),
                        "lab": list(color.descriptor),
                    },
                }
            )
        stem = Path(result.path).stem
        height, width = image.shape[:2]
        payload = {
            "image": Path(result.path).name,
            "size": [width, height],
            "holds": holds,
        }
        (out_dir / f"{stem}.json").write_text(json.dumps(payload), encoding="utf-8")
        cv2.imwrite(str(out_dir / f"{stem}.jpg"), draw(image, polygons, hold_colors))
        names = Counter(h["color"]["name"] for h in holds)
        print(f"{stem}: {len(holds)} holds {dict(names.most_common())}")
    print(f"Results saved to {out_dir}")


def colors_eval(args: argparse.Namespace) -> None:
    from holds.colors import Palette, evaluate

    report = evaluate(
        ROOT / args.data, Palette.load(ROOT / args.palette), tuple(args.splits)
    )
    print(f"accuracy {report['accuracy']:.3f} on {report['holds']} holds")
    for name, (accuracy, count) in report["per_color"].items():
        print(f"  {name:8s} {accuracy:.3f}  (n={count})")
    print("most frequent confusions (truth -> predicted):", report["confusions"])


def main() -> None:
    parser = argparse.ArgumentParser(prog="holds")
    sub = parser.add_subparsers(required=True)

    sub.add_parser("check", help="Verify ultralytics/torch/CUDA setup").set_defaults(
        func=check
    )

    p_merge = sub.add_parser(
        "merge",
        help="Merge Roboflow exports from datasets/ into one hold/volume dataset",
    )
    p_merge.add_argument(
        "sources",
        nargs="*",
        default=["panclimb", "guillaume"],
        help="folders in datasets/",
    )
    p_merge.add_argument("--out", default="datasets/holds")
    p_merge.add_argument("--config", default="configs/holds.yaml")
    p_merge.add_argument(
        "--max-side", type=int, default=1600, help="downscale larger images"
    )
    p_merge.add_argument("--seed", type=int, default=0)
    p_merge.set_defaults(func=merge)

    p_train = sub.add_parser(
        "train", help="Fine-tune a YOLO26-seg model on the holds dataset"
    )
    p_train.add_argument("--model", default="yolo26s-seg.pt")
    p_train.add_argument(
        "--data", default="datasets/holds/data.yaml", help="generated by `holds merge`"
    )
    # Defaults sized for an 8 GB GPU under WSL. Dense walls + mosaic produce
    # 400+ instances per batch: at 1280 px, batch 2 spills into shared RAM and
    # eventually runs out of memory; 1024 px peaks around 6 GB. AutoBatch (-1)
    # is unreliable on WSL (the driver spills instead of failing, so it falls
    # back to batch 16). Ultralytics still accumulates gradients to batch 64.
    p_train.add_argument("--imgsz", type=int, default=1024)
    p_train.add_argument("--epochs", type=int, default=100)
    p_train.add_argument(
        "--batch", type=int, default=2, help="-1 = AutoBatch (unreliable on WSL)"
    )
    p_train.add_argument("--name", default="holds")
    p_train.set_defaults(func=train)

    p_pred = sub.add_parser(
        "predict", help="Run segmentation on images and save overlays"
    )
    p_pred.add_argument("source")
    p_pred.add_argument(
        "--weights", default=str(RUNS_DIR / "holds" / "weights" / "best.pt")
    )
    p_pred.add_argument("--imgsz", type=int, default=1024)
    # 0.10 rather than 0.25: small footholds are found far more often (recall on
    # holds under 25 px goes from 0.47 to 0.66) and the user validates holds anyway.
    p_pred.add_argument("--conf", type=float, default=0.10)
    p_pred.set_defaults(func=predict)

    p_col = sub.add_parser(
        "colors", help="Detect holds and name their colour (JSON + overlay)"
    )
    p_col.add_argument("source", help="image, folder or glob")
    p_col.add_argument(
        "--weights", default=str(RUNS_DIR / "holds" / "weights" / "best.pt")
    )
    p_col.add_argument("--palette", default="configs/colors.yaml")
    p_col.add_argument("--imgsz", type=int, default=1024)
    p_col.add_argument("--conf", type=float, default=0.10)
    p_col.set_defaults(func=colors)

    p_ceval = sub.add_parser(
        "colors-eval", help="Colour naming accuracy on ground-truth hold masks"
    )
    p_ceval.add_argument("--data", default="datasets/holds")
    p_ceval.add_argument("--palette", default="configs/colors.yaml")
    p_ceval.add_argument("--splits", nargs="+", default=["val", "test"])
    p_ceval.set_defaults(func=colors_eval)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
