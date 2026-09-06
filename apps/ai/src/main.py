# @date 2026-09-07
# @file main.py
# @brief Unified application entry point for the Ascension AI service.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Ascension AI Service — Unified CLI and Application Entrypoint.

Usage:
    # Run the RabbitMQ worker (default):
    python src/main.py
    python src/main.py worker

    # Run 2D Pose Analysis standalone (for local dev/testing):
    python src/main.py pose-2d <video.mp4> [--render] [--advice]

    # Run 3D Pose Analysis standalone (for local dev/testing):
    python src/main.py pose-3d <video.mp4> [--render] [--advice]
"""

import sys
from pathlib import Path

# Ensure project root is in sys.path when executed directly as a script
_PROJECT_DIR = Path(__file__).resolve().parent.parent
if str(_PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(_PROJECT_DIR))

from src.pipelines.pose_analysis_2d.cli import main as run_pose_2d  # noqa: E402
from src.pipelines.pose_analysis_3d.cli import main as run_pose_3d  # noqa: E402
from src.worker.runner import run_worker  # noqa: E402


def print_help() -> None:
    """Print top-level usage information."""
    help_text = """Ascension AI Service

Usage:
  python src/main.py [command] [options]

Commands:
  worker                     Start the RabbitMQ AI worker (default)
  pose-2d <video> [options]  Run 2D pose analysis standalone (MediaPipe)
  pose-3d <video> [options]  Run 3D pose analysis standalone (SAM-3D-Body)
  help, -h, --help           Show this help message

Examples:
  uv run python src/main.py
  uv run python src/main.py worker
  uv run python src/main.py pose-2d example/example.mp4 --render --advice
  uv run python src/main.py pose-3d example/example.mp4 --render --advice
"""
    print(help_text)


def main() -> int:
    """Main CLI entry point routing commands to worker or standalone pipelines."""
    args = sys.argv[1:]

    # Default to running the worker if no command is specified
    if not args:
        return run_worker()

    command = args[0]
    sub_args = args[1:]

    if command in ("-h", "--help", "help"):
        print_help()
        return 0
    elif command == "worker":
        return run_worker()
    elif command in ("pose-2d", "pose_2d", "pose_analysis_2d"):
        return run_pose_2d(sub_args)
    elif command in ("pose-3d", "pose_3d", "pose_analysis_3d"):
        return run_pose_3d(sub_args)
    else:
        # If the argument is a video file directly, hint or print help
        print(f"Unknown command: {command!r}\n", file=sys.stderr)
        print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
