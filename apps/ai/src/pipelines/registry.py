# @date 2026-09-05
# @file registry.py
# @brief Registry and factory for AI pipelines.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Registry for AI pipelines."""

from collections.abc import Callable
from typing import TypeVar

from src.core.exceptions import PipelineNotFoundError
from src.core.interfaces import BasePipeline

T = TypeVar("T", bound=type[BasePipeline])


class PipelineRegistry:
    """Central registry mapping pipeline names to their implementation classes."""

    _registry: dict[str, type[BasePipeline]] = {}
    _instances: dict[str, BasePipeline] = {}

    @classmethod
    def register(cls, name: str) -> Callable[[T], T]:
        """Decorator to register a pipeline class under a given name."""

        def decorator(subclass: T) -> T:
            cls._registry[name] = subclass
            return subclass

        return decorator

    @classmethod
    def get(cls, name: str, **kwargs: any) -> BasePipeline:
        """Get or instantiate a pipeline instance by name."""
        if name in cls._instances:
            return cls._instances[name]

        if name not in cls._registry:
            available = ", ".join(cls._registry.keys()) or "none"
            raise PipelineNotFoundError(
                f"Pipeline '{name}' not found. Available pipelines: {available}"
            )

        instance = cls._registry[name](**kwargs)
        cls._instances[name] = instance
        return instance

    @classmethod
    def list_pipelines(cls) -> list[str]:
        """Return a list of all registered pipeline names."""
        return list(cls._registry.keys())

    @classmethod
    def clear(cls) -> None:
        """Clear all registered pipelines (primarily for testing)."""
        cls._registry.clear()
        cls._instances.clear()
