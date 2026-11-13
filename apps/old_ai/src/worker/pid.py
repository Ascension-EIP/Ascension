# @date 2026-09-05
# @file pid.py
# @brief Worker PID lock management to prevent concurrent executions.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""PID lock management for worker."""

import atexit
import logging
import os
import signal
import time

logger = logging.getLogger("ai-worker.pid")


def acquire_pid_lock(pid_file_path: str) -> None:
    """Ensure only one worker instance runs at a time using a PID file."""
    pid_path = os.path.abspath(pid_file_path)
    if os.path.exists(pid_path):
        try:
            with open(pid_path) as f:
                old_pid_str = f.read().strip()
            if old_pid_str:
                old_pid = int(old_pid_str)
                os.kill(old_pid, 0)  # Signal 0 checks if process exists
                logger.warning(
                    "Another worker is already running (PID %d). Terminating it before starting.",
                    old_pid,
                )
                os.kill(old_pid, signal.SIGTERM)
                time.sleep(2)
        except (ProcessLookupError, ValueError):
            pass  # Stale PID file
        except PermissionError:
            logger.warning("Permission denied checking PID file: %s", pid_path)

    os.makedirs(os.path.dirname(pid_path), exist_ok=True)
    with open(pid_path, "w") as f:
        f.write(str(os.getpid()))

    def _cleanup():
        if os.path.exists(pid_path):
            try:
                os.unlink(pid_path)
            except OSError:
                pass

    atexit.register(_cleanup)
