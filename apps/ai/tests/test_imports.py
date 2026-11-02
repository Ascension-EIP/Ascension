# @date 2026-11-01
# @file test_imports.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import subprocess
import sys

CODE = """
import sys
import worker, common.utils.macro
from worker.runtime import get_broker, get_db, get_storage, get_pose_skeleton, get_llm
assert "mediapipe" not in sys.modules, "mediapipe imported"
for g in (get_broker, get_db, get_storage, get_pose_skeleton, get_llm):
    assert g.cache_info().currsize == 0, g.__name__
"""


def test_import_has_no_side_effect():
    r = subprocess.run([sys.executable, "-c", CODE], check=False, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr


def test_help_does_not_load_mediapipe():
    code = "import sys; from worker.cli import build_parser; build_parser(); assert 'mediapipe' not in sys.modules"
    r = subprocess.run([sys.executable, "-c", code], check=False, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
