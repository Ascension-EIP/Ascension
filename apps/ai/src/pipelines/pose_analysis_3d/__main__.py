# @date 2026-09-07
# @file __main__.py
# @brief Direct module execution entry point for pose_analysis_3d.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Main entry point for running pose_analysis_3d via python -m."""

import sys
from src.pipelines.pose_analysis_3d.cli import main

if __name__ == "__main__":
    sys.exit(main())
