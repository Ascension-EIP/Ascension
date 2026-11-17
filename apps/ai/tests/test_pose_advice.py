# @date 2026-11-01
# @file test_pose_advice.py
# @brief Unit tests for step D3 (summary, prompt, validation) with a fake LLM client.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json

import pytest

from common.utils.errors import PermanentError, TransientError
from worker._2_advice.pose_advice import (
    MAX_PROMPT_FRAMES,
    MAX_PROMPT_MOVEMENTS,
    PoseAdvice,
    build_prompt,
    summarize,
)
from worker.cli import main

JOINTS = {"left_hand": "left_wrist", "right_hand": "right_wrist", "left_foot": "left_ankle", "right_foot": "right_ankle"}


def make_result(n=100, blind=(), pose=True, movements=()):
    """``blind``: limbs whose speed is measured on only the first 30% of frames."""
    frames = []
    for i in range(n):
        speeds = {j: 0.5 for limb, j in JOINTS.items() if limb not in blind or i < n * 0.3}
        frames.append(
            {
                "frame": i,
                "timestamp_ms": i * 33,
                "pose_detected": pose,
                "landmarks": {"nose": {"x": 0.1, "y": 0.2, "z": 0.0, "visibility": 1.0}},
                "angles": {"left_elbow": 90.0 + i % 7},
                "speeds": speeds,
            }
        )
    return {
        "fps": 30.0,
        "width": 100,
        "height": 100,
        "frames": frames,
        "metrics": {
            "duration_ms": n * 33,
            "pose_detection_rate": 1.0,
            "avg_speed": {"left_wrist": 0.4, "right_wrist": 0.3},
        },
        "movements": [
            {"limb": "left_hand", "start_frame": s, "end_frame": e, "start_ms": s * 33, "end_ms": e * 33}
            for s, e in movements
        ],
        "pauses": [],
    }


class FakeClient:
    def __init__(self, answer):
        self.answer, self.prompts = answer, []

    def generate_json(self, prompt):
        self.prompts.append(prompt)
        if isinstance(self.answer, Exception):
            raise self.answer
        return self.answer


def hint(**kw):
    return {"category": "technique", "priority": 3, "title": "t", "description": "d", **kw}


def advise(answer, result=None):
    client = FakeClient(answer)
    return PoseAdvice(client, "some-model").process(result or make_result()), client


def test_valid_answer_gives_hints_with_model_and_date_set_by_code():
    answer = {"summary": "ok", "items": [hint()], "model": "evil", "generated_at": "1999-01-01T00:00:00Z"}
    hints, _ = advise(answer)
    assert hints.model == "some-model"
    assert hints.generated_at.year >= 2026
    assert hints.items[0].priority == 3


@pytest.mark.parametrize("bad", [hint(category="cardio"), hint(priority=9), hint(priority=0)])
def test_invalid_category_or_priority_is_rejected(bad):
    with pytest.raises(TransientError):
        advise({"summary": "s", "items": [bad]})


def test_missing_field_is_transient():
    with pytest.raises(TransientError):
        advise({"items": []})


def test_out_of_bounds_frames_are_nulled_and_other_hints_kept():
    answer = {
        "summary": "s",
        "items": [
            hint(frame_start=-5, frame_end=40),
            hint(frame_start=10, frame_end=5000),
            hint(frame_start=60, frame_end=20),
            hint(frame_start=10, frame_end=20),
        ],
    }
    items = advise(answer)[0].items
    assert [(h.frame_start, h.frame_end) for h in items] == [(None, 40), (10, None), (None, None), (10, 20)]


def test_no_pose_is_permanent_and_model_not_called():
    client = FakeClient({})
    with pytest.raises(PermanentError):
        PoseAdvice(client, "m").process(make_result(pose=False))
    assert client.prompts == []


def test_client_errors_propagate():
    with pytest.raises(TransientError):
        advise(TransientError("429"))
    with pytest.raises(PermanentError):
        advise(PermanentError("400"))


def test_prompt_is_bounded_and_has_no_identifier_or_landmark():
    result = make_result(n=20000, movements=[(i * 10, i * 10 + 4) for i in range(1500)])
    result.update(job_id="JOB-SECRET-1", object_key="users/SECRET/video.mp4", user_id="USER-SECRET")
    summary = summarize(result)
    prompt = build_prompt(summary)
    assert len(summary["angle_samples"]) <= MAX_PROMPT_FRAMES
    assert len(summary["movements"]) <= MAX_PROMPT_MOVEMENTS
    assert summary["movements_total"] == 1500
    assert len(prompt) < 20000
    assert "SECRET" not in prompt
    assert "landmarks" not in prompt
    assert "FRENCH" in prompt


def test_key_moments_are_sampled():
    summary = summarize(make_result(movements=[(11, 23)]))
    frames = {s["frame"] for s in summary["angle_samples"]}
    assert {11, 23} <= frames


def test_poorly_measured_limb_is_flagged_not_concluded_on():
    result = make_result(blind=("right_hand",))
    summary = summarize(result)
    cov = summary["measurement_coverage"]
    assert cov["right_hand"] == {"measured_ratio": 0.3, "longest_gap_frames": 70}
    assert cov["left_hand"] == {"measured_ratio": 1.0, "longest_gap_frames": 0}
    assert summary["unreliable_limbs"] == ["right_hand"]
    # The average speed of a barely measured limb is withheld.
    assert summary["metrics"]["avg_speed"] == {"left_wrist": 0.4}
    prompt = build_prompt(summary)
    assert "never draw conclusions" in prompt
    assert "no measure is not no movement" in prompt
    assert '"unreliable_limbs": ["right_hand"]' in prompt


def test_cli_dry_run_writes_prompt_without_key_or_network(tmp_path, monkeypatch):
    for var in ("LLM_BASE_URL", "LLM_API_KEY", "LLM_MODEL"):
        monkeypatch.delenv(var, raising=False)
    src, out = tmp_path / "result.json", tmp_path / "prompt.txt"
    src.write_text(json.dumps(make_result()))
    main(["pose-advice", "--input", str(src), "--out", str(out), "--dry-run"])
    assert "measurement_coverage" in out.read_text()
