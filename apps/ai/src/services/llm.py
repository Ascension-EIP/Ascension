# @date 2026-11-01
# @file llm.py
# @brief Single OpenAI-compatible LLM client (any provider or self-hosted model).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json
import os
from typing import Self

import openai

from common.models.llm import LLMModel
from common.utils.errors import PermanentError, TransientError
from common.utils.logger import log

#: Seconds before a request is abandoned (and retried as a transient failure).
TIMEOUT_S = 60.0
#: The SDK requires a non-empty key even when the server does not check it.
_NO_KEY = "EMPTY"


def classify_error(exc: Exception) -> Exception:
    """Map an OpenAI SDK failure to the worker error taxonomy.

    Returns:
        ``TransientError`` for network failures, timeouts, 408, 429 and 5xx;
        ``PermanentError`` for the other 4xx (bad request, bad key, unknown model).
    """
    if isinstance(exc, openai.APIStatusError):
        status = exc.status_code
        if status in (408, 429) or status >= 500:
            return TransientError(f"LLM temporarily unavailable (HTTP {status})")
        return PermanentError(f"LLM request rejected (HTTP {status})")
    # APIConnectionError also covers APITimeoutError.
    return TransientError(f"LLM unreachable ({type(exc).__name__})")


class LLM:
    def __init__(self):
        self.config: LLMModel | None = None
        self.client: openai.OpenAI | None = None

    def setup_config(self, base_url: str | None = None, model: str | None = None) -> Self:
        """Read ``LLM_BASE_URL``, ``LLM_API_KEY``, ``LLM_MODEL``; arguments take precedence."""
        self.config = LLMModel(
            base_url=base_url or os.getenv("LLM_BASE_URL") or None,
            api_key=os.getenv("LLM_API_KEY", ""),
            model=model or os.getenv("LLM_MODEL") or None,
        )
        missing = [n for n, v in (("LLM_BASE_URL", self.config.base_url), ("LLM_MODEL", self.config.model)) if not v]
        if missing:
            raise ValueError(f"{' and '.join(missing)} must be set (see .env.example).")
        log.info("LLM config: model=%s", self.config.model)
        return self

    def connect(self) -> Self:
        if not self.config:
            self.setup_config()
        # max_retries=0: retries are the caller's job (`with_retry`), not the SDK's.
        self.client = openai.OpenAI(
            base_url=self.config.base_url,
            api_key=self.config.api_key or _NO_KEY,
            timeout=TIMEOUT_S,
            max_retries=0,
        )
        return self

    def generate_json(self, prompt: str) -> dict:
        """Send ``prompt`` in JSON mode and return the parsed object.

        Raises:
            TransientError: Network, timeout, 408/429/5xx, empty or unparsable answer.
            PermanentError: Any other 4xx.
        """
        if not self.client:
            self.connect()
        try:
            response = self.client.chat.completions.create(
                model=self.config.model,
                messages=[{"role": "user", "content": prompt}],
                response_format={"type": "json_object"},
            )
        except openai.OpenAIError as e:
            raise classify_error(e) from e
        content = (response.choices[0].message.content or "").strip() if response.choices else ""
        try:
            data = json.loads(content)
        except ValueError as e:
            raise TransientError("LLM answer is not valid JSON") from e
        if not isinstance(data, dict):
            raise TransientError("LLM answer is not a JSON object")
        return data
