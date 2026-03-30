# Flodo Task Manager

A full-stack task management app built with Flutter (web) and FastAPI.

**Track chosen:** A — Full-Stack Builder
**Stretch Goal:** Debounced Autocomplete Search with text highlighting

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Web / Chrome) |
| Backend | Python — FastAPI |
| Database | SQLite via SQLAlchemy |
| State Management | Provider |
| Local Persistence | SharedPreferences (drafts) |

---

## Project Structure

```
Flodo AI/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI entry point + CORS
│   │   ├── database.py      # SQLite engine + session
│   │   ├── models.py        # SQLAlchemy Task model
│   │   ├── schemas.py       # Pydantic schemas + TaskStatus enum
│   │   └── routes/
│   │       └── tasks.py     # CRUD endpoints
│   └── requirements.txt
└── frontend/
    └── frontend_temp/
        ├── lib/
        │   ├── main.dart
        │   ├── models/task.dart
        │   ├── services/api_service.dart
        │   ├── providers/task_provider.dart
        │   ├── screens/
        │   │   ├── home_screen.dart
        │   │   └── task_form_screen.dart
        │   └── widgets/
        │       ├── task_card.dart
        │       └── highlighted_text.dart
        └── pubspec.yaml
```

---

## Setup Instructions

### Prerequisites

- Python 3.10+
- Flutter SDK (stable)
- Chrome browser

---

### 1. Clone the repository

```bash
git clone https://github.com/26atharvsjadhav/Frido-AI-Task-Management-System
cd "Flodo AI"
```

---

### 2. Backend Setup

```bash
cd backend

# Create and activate virtual environment
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the server
uvicorn app.main:app --reload --port 8000
```

The API will be live at: `http://127.0.0.1:8000`
Swagger docs: `http://127.0.0.1:8000/docs`

---

### 3. Frontend Setup

Open a **new terminal** (keep the backend running):

```bash
cd "frontend/frontend_temp"

flutter pub get

flutter run -d chrome
```

The app opens automatically in Chrome.

> **Note:** The frontend is configured to call `http://127.0.0.1:8000`. If you run on an Android emulator, change `baseUrl` in `lib/services/api_service.dart` to `http://10.0.2.2:8000`.

---

## Features

### Core
- Create, Read, Update, Delete tasks
- Task fields: Title, Description, Due Date, Status, Blocked By
- Blocked tasks are visually greyed out with **"Blocked by: \<task name\>"** label
- Smooth 500ms fade animation when a task becomes unblocked
- 2-second simulated delay on Create and Update with a loading spinner — Save button is disabled during the delay to prevent double submission
- Draft auto-save — if you close or navigate away from the New Task screen, your typed text is restored when you return
- Status filter chips (All / To-Do / In Progress / Done)
- Overdue date shown in red

### Stretch Goal — Debounced Autocomplete Search
- Search bar on the home screen filters tasks by title in real time
- The API call is debounced by **300ms** — no request fires while the user is still typing
- Matching text is **highlighted in yellow** directly inside the task card titles
- Case-insensitive matching on both frontend and backend

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/tasks` | List all tasks (supports `?search=` and `?status=`) |
| POST | `/tasks/` | Create a task (2s delay) |
| PUT | `/tasks/{id}` | Update a task (2s delay) |
| DELETE | `/tasks/{id}` | Delete a task |

---

## One Technical Decision I'm Proud Of

On the backend, the 2-second delay uses `await asyncio.sleep(2)` inside an `async` route instead of the naive `time.sleep(2)`. The difference matters: `time.sleep` blocks the entire server process — no other request can be handled during that window. `asyncio.sleep` yields control back to the event loop, so the server stays responsive and can handle other requests while the delay runs. It's a small change but reflects how production async code should behave.

---

## AI Usage Report

I used Claude as a development tool during this project — primarily to speed up boilerplate, catch syntax issues, and think through edge cases faster. That said, I wrote, reviewed, and debugged every piece of code myself. AI was a faster Stack Overflow, not a replacement for understanding.

### Prompts that gave the most useful output

- *"Write a FastAPI route that simulates a 2-second delay without blocking the server — explain the difference between time.sleep and asyncio.sleep"*
  This gave me the async route pattern and helped me understand why it matters in a real API context.

- *"In Flutter, how do I debounce a search field so the API is only called 300ms after the user stops typing?"*
  The `Timer`-based debounce pattern it returned was clean and I used it directly after verifying it myself.

- *"How do I highlight matching substrings inside a Flutter Text widget without a package?"*
  It pointed me toward `RichText` with `TextSpan` — I then wrote the `HighlightedText` widget myself based on that concept.

### A time AI gave wrong code and how I fixed it

When I asked Claude to set up the `CardTheme` in the Flutter `ThemeData`, it generated:

```dart
cardTheme: CardTheme(
  elevation: 2,
  ...
),
```

This threw a compile error:

```
Error: The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'.
```

The newer Flutter SDK (used in this project) renamed the class to `CardThemeData`. Claude was trained on older Flutter code and used the deprecated class name. I caught it from the error message and fixed it by changing `CardTheme(` to `CardThemeData(`. Small thing, but a good reminder to always read what the compiler tells you rather than blindly trusting generated code.

---

## Demo Video

Drive Link : https://drive.google.com/file/d/1b0M78CFA1OyLGuVEQFDITULXy1yeaoEc/view?usp=drive_link
