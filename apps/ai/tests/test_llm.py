# @date 2026-11-01
# @file test_llm.py
# @brief Unit tests for the OpenAI-compatible LLM service (mocked SDK client).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from types import SimpleNamespace
from unittest.mock import MagicMock

import openai
import pytest

from common.utils.errors import PermanentError, TransientError
from services.llm import LLM

REQUEST = MagicMock()  # the SDK only stores it; no HTTP library needed here


def status_error(code):
    response = SimpleNamespace(status_code=code, headers={}, request=REQUEST)
    return openai.APIStatusError("boom", response=response, body=None)


def make_llm(create):
    llm = LLM().setup_config("http://llm.test/v1", "any-model")
    llm.client = MagicMock()
    llm.client.chat.completions.create = create
    return llm


def answer(content):
    return MagicMock(return_value=SimpleNamespace(choices=[SimpleNamespace(message=SimpleNamespace(content=content))]))


def test_returns_parsed_json_in_json_mode():
    create = answer('{"summary": "ok"}')
    assert make_llm(create).generate_json("hi") == {"summary": "ok"}
    kwargs = create.call_args.kwargs
    assert kwargs["response_format"] == {"type": "json_object"}
    assert kwargs["model"] == "any-model"


@pytest.mark.parametrize("code", [408, 429, 500, 503])
def test_retryable_http_statuses_are_transient(code):
    with pytest.raises(TransientError):
        make_llm(MagicMock(side_effect=status_error(code))).generate_json("hi")


@pytest.mark.parametrize("code", [400, 401, 404])
def test_other_4xx_are_permanent(code):
    with pytest.raises(PermanentError):
        make_llm(MagicMock(side_effect=status_error(code))).generate_json("hi")


@pytest.mark.parametrize("exc", [openai.APIConnectionError(request=REQUEST), openai.APITimeoutError(request=REQUEST)])
def test_network_and_timeout_are_transient(exc):
    with pytest.raises(TransientError):
        make_llm(MagicMock(side_effect=exc)).generate_json("hi")


@pytest.mark.parametrize("content", ["not json", "", None, "[1, 2]"])
def test_unreadable_answer_is_transient(content):
    with pytest.raises(TransientError):
        make_llm(answer(content)).generate_json("hi")


def test_config_needs_base_url_and_model_but_not_a_key(monkeypatch):
    for var in ("LLM_BASE_URL", "LLM_API_KEY", "LLM_MODEL"):
        monkeypatch.delenv(var, raising=False)
    with pytest.raises(ValueError, match="LLM_BASE_URL and LLM_MODEL"):
        LLM().setup_config()
    monkeypatch.setenv("LLM_BASE_URL", "http://x/v1")
    monkeypatch.setenv("LLM_MODEL", "m")
    llm = LLM().setup_config()
    assert llm.config.api_key == ""
    assert llm.setup_config(model="other").config.model == "other"


def test_config_log_does_not_expose_the_base_url_or_key(monkeypatch):
    log = MagicMock()
    monkeypatch.setattr("services.llm.log", log)
    monkeypatch.setenv("LLM_API_KEY", "sk-secret")
    LLM().setup_config("http://user:token@llm.test/v1", "any-model")
    logged = " ".join(str(a) for call in log.mock_calls for a in call.args)
    assert "token" not in logged and "llm.test" not in logged and "sk-secret" not in logged
    assert "any-model" in logged
