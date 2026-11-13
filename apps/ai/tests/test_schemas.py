# @date 2026-11-01
# @file test_schemas.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json
import re
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4

import pytest
from pydantic import ValidationError

from common.db_schemas.analysis import Analysis
from shared.models import AnalysisResult, Hints, JobStatus, PoseDetectRequest, Status

DOC = Path(__file__).parents[3] / "docs/Ascension/developer/architecture/specifications/database-schema.md"
HINT = {"category": "technique", "priority": 1, "title": "t", "description": "d"}
HINTS = {"summary": "s", "items": [HINT], "model": "m", "generated_at": "2026-09-18T10:12:00Z"}
RESULT = {"fps": 30.0, "width": 1080, "height": 1920, "frames": []}


def test_job_status_message_is_optional():
    assert JobStatus(job_id="x", status=Status.PENDING).message is None


def test_pose_detect_request_requires_object_key():
    with pytest.raises(ValidationError):
        PoseDetectRequest.model_validate({"job_id": "x"})


@pytest.mark.skipif(not DOC.exists(), reason="docs not available")
def test_doc_examples_validate():
    section = DOC.read_text().split("### 6.3 `analyses`")[1].split("### 6.4")[0]
    result, hints = (json.loads(b) for b in re.findall(r"```json\n(.*?)```", section, re.DOTALL))
    AnalysisResult.model_validate(result)
    Hints.model_validate(hints)


def test_partial_result_and_full_result():
    frame = {"frame": 0, "timestamp_ms": 0, "pose_detected": True, "landmarks": {}, "angles": {}}
    AnalysisResult.model_validate({**RESULT, "frames": [frame]})
    full = {
        **RESULT,
        "frames": [{**frame, "speeds": {"left_wrist": 0.4}, "arm_extension": {"left": 0.9, "right": 0.7}}],
        "metrics": {"duration_ms": 1, "pose_detection_rate": 1.0, "bent_arm_ratio": {"left": 0, "right": 0}},
        "movements": [{"limb": "left_hand", "start_frame": 1, "end_frame": 2, "start_ms": 3, "end_ms": 4}],
        "pauses": [{"start_frame": 1, "end_frame": 2, "start_ms": 3, "end_ms": 4}],
    }
    AnalysisResult.model_validate(full)


def test_status_has_a_single_definition():
    from common.db_schemas import analysis

    assert analysis.Status is Status
    assert not hasattr(analysis, "JobStatus")


def test_analysis_rejects_unknown_result_key():
    Analysis(video_id=uuid4(), result=RESULT)
    with pytest.raises(ValidationError):
        Analysis(video_id=uuid4(), result={**RESULT, "oops": 1})


@pytest.mark.parametrize("priority", [0, 6])
def test_analysis_rejects_out_of_range_priority(priority):
    hints = {**HINTS, "items": [{**HINT, "priority": priority}]}
    with pytest.raises(ValidationError):
        Analysis(video_id=uuid4(), hints=hints)


def test_analysis_success_needs_result_and_completed_at():
    with pytest.raises(ValidationError):
        Analysis(video_id=uuid4(), status=Status.SUCCESS)
    Analysis(video_id=uuid4(), status=Status.SUCCESS, result=RESULT, completed_at=datetime.now(UTC))
