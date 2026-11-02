# @date 2026-11-01
# @file test_cli.py
# @brief Runs every `worker` sub-command as a real process on the example video, chaining their outputs.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import subprocess
import sys
from pathlib import Path

import pytest

from shared.models import AnalysisResult

pytestmark = pytest.mark.functional

APP = Path(__file__).resolve().parents[2]  # apps/ai: the model path is relative to it
VIDEO = APP / "resources" / "example-2.mp4"
WORKER = Path(sys.executable).parent / "worker"  # the installed entry point
TIMEOUT_S = 300


def run(*args: object) -> subprocess.CompletedProcess:
    return subprocess.run(
        [str(WORKER), *map(str, args)], cwd=APP, check=False, capture_output=True, text=True, timeout=TIMEOUT_S
    )


def ok(*args: object) -> None:
    r = run(*args)
    assert r.returncode == 0, f"worker {args[0]} failed:\n{r.stdout}\n{r.stderr}"


@pytest.fixture(scope="module")
def chain(tmp_path_factory) -> dict[str, Path]:
    """skeleton -> filter -> metrics -> movements, then detect on its own."""
    d = tmp_path_factory.mktemp("cli")
    p = {n: d / f"{n}.json" for n in ("skeleton", "filter", "metrics", "movements", "detect")}
    ok("pose-skeleton", "--video", VIDEO, "--out", p["skeleton"])
    ok("pose-filter", "--input", p["skeleton"], "--out", p["filter"])
    ok("pose-metrics", "--input", p["filter"], "--out", p["metrics"])
    ok("pose-movements", "--input", p["metrics"], "--out", p["movements"])
    ok("pose-detect", "--video", VIDEO, "--out", p["detect"])
    return p


def load(path: Path) -> AnalysisResult:
    return AnalysisResult.model_validate_json(path.read_text())


def test_every_step_output_matches_the_generated_schema(chain):
    frames = {name: load(path).frames for name, path in chain.items()}
    assert len(frames["skeleton"]) > 0
    assert len({len(f) for f in frames.values()}) == 1  # no step drops or adds frames
    assert any(f.pose_detected for f in frames["skeleton"])


def test_each_step_adds_its_own_data(chain):
    # Only filter/metrics/movements enrich the result; the raw skeleton has none of it.
    raw, final = load(chain["skeleton"]), load(chain["movements"])
    assert raw.metrics is None and raw.movements is None
    assert final.metrics is not None and final.movements is not None


def test_detect_equals_the_chained_steps(chain):
    assert load(chain["detect"]) == load(chain["movements"])


def test_advice_dry_run_writes_the_prompt_without_network(chain, tmp_path):
    out = tmp_path / "prompt.txt"
    ok("pose-advice", "--input", chain["detect"], "--out", out, "--dry-run")
    prompt = out.read_text()
    assert "FRENCH" in prompt and str(VIDEO) not in prompt  # instructions in, no path or identifier out


def test_advice_without_llm_configuration_fails_cleanly(chain, tmp_path, monkeypatch):
    for var in ("LLM_BASE_URL", "LLM_MODEL", "LLM_API_KEY"):
        monkeypatch.setenv(var, "")
    r = run("pose-advice", "--input", chain["detect"], "--out", tmp_path / "hints.json")
    assert r.returncode != 0 and not (tmp_path / "hints.json").exists()
    assert "Traceback" not in r.stderr


@pytest.mark.parametrize(
    "step, flag",
    [("pose-skeleton", "--video"), ("pose-detect", "--video")],
)
def test_invalid_video_gives_a_non_zero_code(tmp_path, step, flag):
    bad = tmp_path / "bad.mp4"
    bad.write_text("this is not a video")
    out = tmp_path / "out.json"
    r = run(step, flag, bad, "--out", out)
    assert r.returncode != 0 and not out.exists()


@pytest.mark.parametrize("step", ["pose-filter", "pose-metrics", "pose-movements", "pose-advice"])
def test_invalid_or_missing_input_gives_a_non_zero_code(tmp_path, step):
    extra = ["--dry-run"] if step == "pose-advice" else []
    out = tmp_path / "out.json"
    missing = run(step, "--input", tmp_path / "missing.json", "--out", out, *extra)
    garbage = tmp_path / "garbage.json"
    garbage.write_text("{not json")
    invalid = run(step, "--input", garbage, "--out", out, *extra)
    assert missing.returncode != 0 and invalid.returncode != 0 and not out.exists()


def test_unknown_step_and_missing_argument_are_rejected():
    assert run("pose-nothing").returncode == 2
    assert run("pose-detect", "--video", VIDEO).returncode == 2  # --out is required


def test_render_option_writes_a_video(tmp_path):
    video = tmp_path / "skeleton.mp4"
    ok("pose-skeleton", "--video", VIDEO, "--out", tmp_path / "raw.json", "--render", video)
    assert video.stat().st_size > 0
