import time
import asyncio
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional

from .. import models, schemas
from ..database import get_db

router = APIRouter(prefix="/tasks", tags=["Tasks"])

SIMULATED_DELAY_SECONDS = 2


# ─── CREATE ───────────────────────────────────────────────────────────────────

@router.post("/", response_model=schemas.TaskOut, status_code=201)
async def create_task(task: schemas.TaskCreate, db: Session = Depends(get_db)):
    """Create a new task with a simulated 2-second processing delay."""
    # Validate blocked_by references a real task
    if task.blocked_by is not None:
        blocker = db.query(models.Task).filter(models.Task.id == task.blocked_by).first()
        if not blocker:
            raise HTTPException(status_code=404, detail=f"Blocker task {task.blocked_by} not found")

    await asyncio.sleep(SIMULATED_DELAY_SECONDS)  # non-blocking delay

    new_task = models.Task(**task.model_dump())
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task


# ─── READ ALL (Search + Filter) ───────────────────────────────────────────────

@router.get("/", response_model=list[schemas.TaskOut])
def get_tasks(
    search: Optional[str] = Query(default=None, description="Search by title (case-insensitive)"),
    status: Optional[schemas.TaskStatus] = Query(default=None, description="Filter by status"),
    db: Session = Depends(get_db),
):
    """Retrieve all tasks, with optional title search and status filter."""
    query = db.query(models.Task)

    if search:
        query = query.filter(models.Task.title.ilike(f"%{search}%"))

    if status:
        query = query.filter(models.Task.status == status.value)

    return query.order_by(models.Task.id).all()


# ─── READ ONE ─────────────────────────────────────────────────────────────────

@router.get("/{task_id}", response_model=schemas.TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db)):
    """Retrieve a single task by ID."""
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


# ─── UPDATE ───────────────────────────────────────────────────────────────────

@router.put("/{task_id}", response_model=schemas.TaskOut)
async def update_task(task_id: int, task: schemas.TaskUpdate, db: Session = Depends(get_db)):
    """Update a task by ID with a simulated 2-second processing delay."""
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Validate blocked_by references a real task and prevent self-reference
    if task.blocked_by is not None:
        if task.blocked_by == task_id:
            raise HTTPException(status_code=400, detail="A task cannot block itself")
        blocker = db.query(models.Task).filter(models.Task.id == task.blocked_by).first()
        if not blocker:
            raise HTTPException(status_code=404, detail=f"Blocker task {task.blocked_by} not found")

    await asyncio.sleep(SIMULATED_DELAY_SECONDS)  # non-blocking delay

    for key, value in task.model_dump().items():
        setattr(db_task, key, value)

    db.commit()
    db.refresh(db_task)
    return db_task


# ─── DELETE ───────────────────────────────────────────────────────────────────

@router.delete("/{task_id}", status_code=200)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    """Delete a task by ID. Clears blocked_by references from other tasks."""
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Clear blocked_by for any task that depended on this one
    db.query(models.Task).filter(models.Task.blocked_by == task_id).update(
        {"blocked_by": None}, synchronize_session=False
    )

    db.delete(task)
    db.commit()
    return {"message": f"Task {task_id} deleted successfully"}
