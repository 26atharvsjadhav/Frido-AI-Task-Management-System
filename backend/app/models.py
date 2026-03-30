from sqlalchemy import Column, Integer, String, Date, ForeignKey
from sqlalchemy.orm import relationship
from .database import Base


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False, default="")
    due_date = Column(Date, nullable=False)
    status = Column(String, nullable=False, default="To-Do")
    blocked_by = Column(Integer, ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True)

    # Self-referential relationship for blocked_by
    blocker = relationship("Task", remote_side=[id], foreign_keys=[blocked_by])
