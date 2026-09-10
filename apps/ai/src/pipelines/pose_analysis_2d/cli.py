# @date 2026-09-05
# @file cli.py
# @brief Standalone CLI for 2D pose analysis development.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Standalone CLI for 2D Pose Analysis."""

import argparse
import json
import logging
import os
import sys
from pathlib import Path

_PROJECT_DIR = Path(__file__).resolve().parent.parent.parent.parent
if str(_PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(_PROJECT_DIR))

from src.pipelines.pose_analysis_2d.pipeline import PoseAnalysis2DPipeline  # noqa: E402
from src.pipelines.pose_analysis_2d.renderer import render_annotated_video  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    """Entry point for standalone 2D pose analysis."""
    parser = argparse.ArgumentParser(
        prog="pose_analysis_2d",
        description="Ascension — 2D Pose Analysis",
    )
    parser.add_argument("video", help="Path to input video file")
    parser.add_argument(
        "-o",
        "--output",
        default="biomechanics_2d.json",
        help="Destination JSON output path (default: biomechanics_2d.json)",
    )
    parser.add_argument(
        "--render",
        action="store_true",
        help="Generate annotated MP4 video with skeleton overlay",
    )
    parser.add_argument(
        "--render-output",
        metavar="PATH",
        help="Destination annotated MP4 path (default: <video>-postanalyse.mp4)",
    )
    parser.add_argument(
        "--render-only",
        metavar="JSON",
        help="Skip inference and render video directly from an existing JSON file",
    )
    parser.add_argument(
        "--advice",
        action="store_true",
        help="Request climbing coaching advice from Gemini",
    )
    parser.add_argument(
        "--model-path",
        default="",
        help="Custom path to pose_landmarker.task model",
    )

    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    )

    def default_render_path(video: str, override: str | None) -> str:
        if override:
            return override
        base, _ = os.path.splitext(video)
        return f"{base}-postanalyse.mp4"

    if args.render_only:
        out_vid = default_render_path(args.video, args.render_output)
        render_annotated_video(args.video, args.render_only, out_vid)
        print(f"Annotated video generated: {out_vid}")
        return 0

    pipeline = PoseAnalysis2DPipeline(model_path=args.model_path or None)

    print(f"Starting 2D pose analysis on {args.video}...")
    result = pipeline.analyze(args.video)

    with open(args.output, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Analysis complete. Results saved to: {args.output}")

    if args.advice:
        print("\n--- Requesting Gemini 2D Coaching Advice ---")
        advice = pipeline.generate_advice(result)
        if advice:
            print(f"\n{advice}\n")
        else:
            print("No advice generated (check your GEMINI_API_KEY).")

    if args.render:
        out_vid = default_render_path(args.video, args.render_output)
        render_annotated_video(args.video, result, out_vid)
        print(f"Annotated video saved to: {out_vid}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
