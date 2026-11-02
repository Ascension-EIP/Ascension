# @date 2026-11-01
# @file llm.py
# @brief Configuration model of the OpenAI-compatible LLM client.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from pydantic import BaseModel


class LLMModel(BaseModel):
    base_url: str | None = None
    api_key: str = ""
    """May stay empty for a self-hosted server without authentication."""
    model: str | None = None
