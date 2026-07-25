# Cikgu Web Application

Django web app for the **Cikgu Personalized Learning Platform** — ICT502
Database Engineering group project. All data access is hand-written SQL
through `django.db.connection` cursors (see `cikguapp/db.py` and
`cikguapp/repositories/`) — deliberately no Django ORM models, against the
`CIKGU` Oracle schema. There's also no `django.contrib.auth`: login is a
small session-based auth layer (`cikguapp/auth.py`) that queries `app_user`
directly and checks bcrypt hashes, and sessions are signed cookies, so this
app never creates or manages a single database table beyond what
[`db/cikgu_install.sql`](../../db/cikgu_install.sql) already created.

For the full architecture writeup (request lifecycle, data-access layer,
auth design, page-by-page walkthrough, demo script), see
[`../../docs/index.html`](../../docs/index.html).

## Prerequisites

1. Python 3.11+.
2. The database running with the CIKGU schema installed. From the repository
   root, one command does both — `scripts\setup.ps1` on Windows,
   `./scripts/setup.sh` on macOS/Linux. See the [repository README](../../README.md).

No Oracle client installation is needed: `python-oracledb` connects in thin
mode, which is pure Python.

## Run

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

Open <http://localhost:8000>. Log in with a seeded account (password
`password123` for all of them), e.g.:

| Email | Role |
|---|---|
| `halim.abdullah@cikgu.my` | Tutor (mentors several tutors, leads SQL Fundamentals) |
| `aina.sofea@cikgu.my` | Learner (goals + enrollments seeded) |

or register a fresh Learner/Tutor account.

Connection settings default to `localhost:1521/FREEPDB1`, user `cikgu` /
`Cikgu_123` — the schema target the repo's Docker Oracle container is set up
for — and can be overridden with the `CIKGU_DB_HOST`, `CIKGU_DB_PORT`,
`CIKGU_DB_SERVICE`, `CIKGU_DB_USER`, `CIKGU_DB_PASSWORD` environment
variables — see `cikgu/settings.py`.

## Feature map (course rubric → screen)

| Rubric item | Where |
|---|---|
| Insert | Register, create goal, create module, enroll, add co-teacher |
| Read | Browse modules, dashboards, reports, profile |
| Update | Edit goal, edit module, update progress/status, edit profile |
| Delete | Delete goal, cancel enrollment, remove co-teacher, delete module |
| Bridge entity #1 | Learner → Browse Modules → Enroll (ENROLLMENT, carries goal link) |
| Bridge entity #2 | Tutor → My Modules → Co-teachers (MODULE_TUTOR, LEAD/CO_TEACHER) |
| Recursive | Tutor → Mentorship (CONNECT BY PRIOR tree + mentor assignment) |
| Inheritance | Registration (APP_USER + subclass in one transaction) and Profile page |
| Transaction demo | `cikguapp/services.py`: `register()`, `create_module()` |
| Trigger demo | Tutor → Learner Progress (updates stamp `last_updated_at`) |
| View demo | Reports page reads `module_progress_v` |
| Extra: SQL console | SQL Console (read-only SELECT, both roles) |
| Extra: chart | Reports page (Chart.js bar chart, served locally) |

## Project layout

```
cikgu/                  Django project config (settings, urls)
cikguapp/
  db.py                 Raw-SQL cursor helpers (dictfetchall, etc.)
  auth.py                Session-based login/register/logout + role decorators
  console.py              Read-only SQL console service
  services.py             Multi-statement transaction demos
  repositories/            One module per table/bridge, hand-written SQL
  views/                   One module per original controller
  templates/cikguapp/      Django templates
  static/cikguapp/         CSS + Chart.js
```
