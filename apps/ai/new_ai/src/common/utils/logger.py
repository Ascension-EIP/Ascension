# @date 2026-09-10
# @file logger.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import logging
from logging import Logger

from rich.logging import RichHandler

FORMAT = "%(name)s: %(message)s"
logging.basicConfig(
    level="NOTSET",
    format=FORMAT,
    datefmt="[%X]",
    handlers=[RichHandler(rich_tracebacks=True)],
)
log: Logger = logging.getLogger(__name__)
