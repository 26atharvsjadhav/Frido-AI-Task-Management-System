from pydantic import BaseModel, field_validator
from datetime import date
from typing import Optional
from enum import Enum


class TaskStatus(str, Enum):
    todo = "To-Do"
    in_progress = "In Progress"
    done = "Done"


class TaskBase(BaseModel):
    title: str
    description: str = ""
    due_date: date
    status: TaskStatus = TaskStatus.todo
    blocked_by: Optional[int] = None

    @field_validator("title")
    @classmethod
    def title_must_not_be_empty(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Title cannot be empty")
        return v


class TaskCreate(TaskBase):
    pass


class TaskUpdate(TaskBase):
    pass


class TaskOut(TaskBase):
    id: int

    model_config = {"from_attributes": True}
