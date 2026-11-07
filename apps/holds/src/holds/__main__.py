"""Hold detection CLI: check, train, predict."""

import argparse
from pathlib import Path

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


def main() -> None:
    parser = argparse.ArgumentParser(prog="holds")
    sub = parser.add_subparsers(required=True)

    sub.add_parser("check", help="Verify ultralytics/torch/CUDA setup").set_defaults(func=check)

    p_train = sub.add_parser("train", help="Fine-tune a YOLO26-seg model on the holds dataset")
    p_train.add_argument("--model", default="yolo26s-seg.pt")
    p_train.add_argument("--data", default="configs/holds.yaml")
    p_train.add_argument("--imgsz", type=int, default=1280)
    p_train.add_argument("--epochs", type=int, default=100)
    p_train.add_argument("--batch", type=int, default=-1, help="-1 = auto-fit GPU memory")
    p_train.add_argument("--name", default="holds")
    p_train.set_defaults(func=train)

    p_pred = sub.add_parser("predict", help="Run segmentation on images and save overlays")
    p_pred.add_argument("source")
    p_pred.add_argument("--weights", default=str(RUNS_DIR / "holds" / "weights" / "best.pt"))
    p_pred.add_argument("--imgsz", type=int, default=1280)
    p_pred.add_argument("--conf", type=float, default=0.25)
    p_pred.set_defaults(func=predict)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
