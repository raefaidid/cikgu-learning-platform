# Cikgu — Personalized Learning Platform

**ICT502 Database Engineering — Group Project (NBCS2306A, Group 3)**
Universiti Teknologi MARA, Faculty of Computer and Mathematical Sciences
Prepared for: Dr. Nor Diana Binti Ahmad

| Name | Student ID |
|---|---|
| Raef Luqman Bin Mohammad Aidid | 2022673128 |
| Amrina Binti Shamsudin | 2023280798 |
| Nurathika Nazira Binti Musa | 2024478332 |
| Siti Syazila Binti Bidin | 2023954993 |

---

## What is Cikgu?

Cikgu (Malay for "teacher") is a fictional Ed-Tech startup used as the case
study for this project. Independent tutors and small learning centres today
run on spreadsheets, WhatsApp messages, and scattered documents — there is no
central system to track learners, so tutors can't easily answer basic
questions like *"who's behind schedule?"* or *"which modules are actually
working?"* without manual, error-prone aggregation.

Cikgu is a web-based, goal-centric learning platform that replaces that manual
process with a single Oracle-backed system: learners define a personal
learning goal and enroll in modules toward it, tutors (organized in a
mentorship hierarchy) lead or co-teach those modules and track learner
progress, and a reporting dashboard answers the "who's behind, what's working"
questions directly from the database.

As a course project, the assignment's actual deliverable is **the database
design and its implementation** — the web app exists to demonstrate that
design working end-to-end, not the other way around.

## What this repository contains

This project has two halves:

```
db/                     ← the database: DDL, seed data, 10 ad hoc queries
docs/                   ← proposal, rubrics, technical guide
src/cikgu-app-django/   ← the web application (Python + Django)
docker-compose.yml      ← the Oracle 23ai Free container both halves run against
scripts/setup.ps1       ← one-command setup (Windows)
scripts/setup.sh        ← one-command setup (macOS / Linux)
```

The web app is hand-written-SQL only (no ORM), points at the `CIKGU` Oracle
schema, and implements the full feature set the course rubric grades —
insert/read/update/delete, both bridge entities, the recursive mentorship
query, the inheritance-demo profile page, transaction demos, a trigger, a
reporting view, and an ad hoc SQL console.

| Read this... | ...if you want to |
|---|---|
| [`docs/index.html`](docs/index.html) | Understand the tech stack from scratch, run the system locally, and see what every page does (with a suggested presentation script) — HTML, open it in a browser |
| [`db/README.md`](db/README.md) | Install/uninstall the database schema directly |
| [`db/data_dictionary.md`](db/data_dictionary.md) | Table/column reference for the report appendix |
| [`src/cikgu-app-django/README.md`](src/cikgu-app-django/README.md) | Run the web app |
| `docs/project_description.pdf`, `docs/project_rubrics.pdf` | The lecturer's official assignment brief and grading rubrics |
| `docs/CHCECKED Cikgu Personalized Learning Platform ICT502_GROUP_3_PROPOSAL.pdf` | Our graded proposal (company background, problem statement, objectives, original ERD) |

## Quick start

You need **Docker Desktop** and **Python 3.11+**. You do *not* need to install
Oracle, an Oracle client, or SQL Developer — the database runs in Docker and
the app talks to it in pure Python.

### 1. Set up the database

Clone the repository, then from its root run the setup script for your OS. It
starts Oracle, waits for it to be ready, and installs the schema with seed data.

**Windows (PowerShell)**

```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
```

**macOS / Linux**

```bash
./scripts/setup.sh
```

The first run downloads a ~2 GB image and takes **5–15 minutes** — Oracle is
slow to start the first time. The script prints `Database is ready.` when it
has finished. Later runs take a few seconds.

### 2. Run the app

**Windows (PowerShell)**

```powershell
cd src\cikgu-app-django
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py runserver
```

**macOS / Linux**

```bash
cd src/cikgu-app-django
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python manage.py runserver
```

Open **http://localhost:8000** and log in with any seeded account — password
`password123` for all of them (e.g. `halim.abdullah@cikgu.my`). Full
instructions and login options are in [`docs/index.html`](docs/index.html).

### Everyday commands

| Task | Command (from the repository root) |
|---|---|
| Stop the database | `docker compose stop` |
| Start it again | `docker compose start` |
| Reset the demo data | re-run the setup script |
| Wipe everything and start over | `docker compose down -v`, then re-run setup |
| See what the database is doing | `docker compose logs -f` |

### Troubleshooting

| Symptom | Fix |
|---|---|
| `docker: command not found` / "Docker daemon is not running" | Install Docker Desktop and wait until it reports *Engine running*. On Windows it needs the WSL 2 backend. |
| `port is already allocated` | Something else uses port 1521. Set `ORACLE_HOST_PORT=1522` in `.env`, re-run setup, and start the app with `$env:CIKGU_DB_PORT='1522'` (PowerShell) or `export CIKGU_DB_PORT=1522`. |
| `ORA-01017: invalid credential` | The container was created with a different password than the one now in `.env`. Run `docker compose down -v` and re-run setup. |
| Setup times out waiting for health | Give Docker Desktop more memory (Settings → Resources → at least 4 GB) and re-run. Check progress with `docker compose logs -f`. |
| `ORA-12541`/`could not connect` from Django | The database isn't running. `docker compose start`, wait for `docker ps` to show *healthy*. |
| `scripts\setup.ps1 cannot be loaded because running scripts is disabled` | Use the `-ExecutionPolicy Bypass` form shown above. |

## Tech stack at a glance

Oracle Database 23ai (in Docker) · Python 3 + Django · Django templates
(server-rendered, no separate frontend build) · hand-written SQL through
`django.db.connection` cursors (no ORM) · a small custom session-based auth
layer (bcrypt password hashing, signed-cookie sessions — no
`django.contrib.auth`, no Django-managed database tables) · Chart.js. See
the technical guide for *why* each piece was chosen.

## Database design highlights

Seven tables built around the entities the course rubric grades by name:

- **Inheritance / disjoint specialization** — `APP_USER` is the superclass;
  `LEARNER` and `TUTOR` are subclasses keyed off `user_type`.
- **Recursive relationship** — `TUTOR.mentor_id` self-references
  `TUTOR.user_id` (multi-level mentorship chains).
- **Two bridge entities** — `ENROLLMENT` (`LEARNER` × `MODULE`, carrying a
  goal link) and `MODULE_TUTOR` (`MODULE` × `TUTOR`, carrying a LEAD/CO_TEACHER
  role, with exactly one LEAD per module enforced by the database itself).
- **Sequence + trigger surrogate keys**, FK indexes, a `BEFORE UPDATE` audit
  trigger, and a reporting view (`module_progress_v`) backing the dashboard.

Full column-level detail: [`db/data_dictionary.md`](db/data_dictionary.md).

## Scope

| In scope | Out of scope |
|---|---|
| Web platform for learners and tutors | Payment/billing |
| Role-based registration (Learner / Tutor) | Live video conferencing |
| Learner goals, module browsing and enrollment | Native mobile app |
| Tutor mentorship hierarchy, co-teaching | Resume parsing / AI features |
| Progress tracking and reporting dashboard | Automated assessment scoring |
| SQL-based reports and 10+ ad hoc queries | Session scheduling, production hosting |
