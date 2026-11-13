# @date 2026-09-05
# @file security.py
# @brief Security helpers for masking sensitive environment data in logs.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Security helpers for masking sensitive data."""

_SENSITIVE_KEYWORDS = (
    "password",
    "secret",
    "token",
    "key",
    "pass",
    "auth",
    "credential",
)


def is_sensitive_key(key: str) -> bool:
    """Check if a key name suggests sensitive content."""
    k = key.lower()
    return any(word in k for word in _SENSITIVE_KEYWORDS)


def mask_value(val: str | None) -> str:
    """Mask sensitive string value for safe logging."""
    if not val:
        return "<empty>"
    if len(val) <= 4:
        return "***"
    return f"{val[:2]}***{val[-2:]}"


def mask_dict(data: dict[str, any]) -> dict[str, any]:
    """Return a shallow copy of a dict with sensitive keys masked."""
    result = {}
    for k, v in data.items():
        if is_sensitive_key(k) and isinstance(v, str):
            result[k] = mask_value(v)
        elif isinstance(v, dict):
            result[k] = mask_dict(v)
        else:
            result[k] = v
    return result
