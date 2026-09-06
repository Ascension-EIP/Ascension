# @date 2026-09-07
# @file __main__.py
# @brief Direct execution entry point for worker (python -m src.worker).
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Direct execution entry point for worker."""

import sys
from src.worker.runner import run_worker

if __name__ == "__main__":
    sys.exit(run_worker())
