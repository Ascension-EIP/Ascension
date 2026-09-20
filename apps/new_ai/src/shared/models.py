# @date 2026-09-18
# @file models.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from enum import StrEnum

from pydantic import BaseModel


class Job(BaseModel):
    job_id: str


class Status(StrEnum):
    FAILED = "failed"
    PENDING = "pending"
    RUNNING = "running"
    STARTED = "started"
    SUCCESS = "success"


class JobStatus(BaseModel):
    job_id: str
    status: Status
    message: str | None = None


class RoutingKey(StrEnum):
    POSE_ADVICE_REQUESTED = "pose.advice.requested"
    POSE_ADVICE_STATUS = "pose.advice.status"
    POSE_DETECT_COMPLETED = "pose.detect.completed"
    POSE_DETECT_REQUESTED = "pose.detect.requested"
    POSE_DETECT_STATUS = "pose.detect.status"
