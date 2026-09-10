# @date 2026-09-10
# @file errors.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from pydantic import BaseModel


def throw_if_none(model: BaseModel):
    fields_with_none = [
        field for field, value in model.model_dump().items() if value is None
    ]
    raise ValueError(f"fields: {fields_with_none} are mandatory.")
