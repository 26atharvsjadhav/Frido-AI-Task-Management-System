from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import Base, engine
from .routes import tasks

# Create all DB tables on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Flodo Task Manager API",
    description="REST API for the Flodo AI Take-Home Task Management App",
    version="1.0.0",
)

# Allow Flutter app (any origin during development) to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tasks.router)


@app.get("/", tags=["Health"])
def root():
    return {"message": "Flodo Task API is running 🚀"}
