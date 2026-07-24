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

This project has two halves, kept in the two locations the course expects:

```
schema/cikgu/                          ← the database: DDL, seed data, 10 ad hoc queries
projects/ICT502_GROUP/
├── docs/                              ← YOU ARE HERE — proposal, rubrics, technical guide
└── src/cikgu-app-django/              ← the web application (Python + Django)
```

The web app is hand-written-SQL only (no ORM), points at the `CIKGU` Oracle
schema, and implements the full feature set the course rubric grades —
insert/read/update/delete, both bridge entities, the recursive mentorship
query, the inheritance-demo profile page, transaction demos, a trigger, a
reporting view, and an ad hoc SQL console.

| Read this... | ...if you want to |
|---|---|
| [`docs/index.html`](docs/index.html) | Understand the tech stack from scratch, run the system locally, and see what every page does (with a suggested presentation script) — HTML, open it in a browser |
| [`../../schema/cikgu/README.md`](../../schema/cikgu/README.md) | Install/uninstall the database schema directly |
| [`../../schema/cikgu/data_dictionary.md`](../../schema/cikgu/data_dictionary.md) | Table/column reference for the report appendix |
| [`src/cikgu-app-django/README.md`](src/cikgu-app-django/README.md) | Run the web app |
| `docs/project_description.pdf`, `docs/project_rubrics.pdf` | The lecturer's official assignment brief and grading rubrics |
| `docs/CHCECKED Cikgu Personalized Learning Platform ICT502_GROUP_3_PROPOSAL.pdf` | Our graded proposal (company background, problem statement, objectives, original ERD) |

## Quick start

```bash
# 1. Start Oracle (from the repository root)
./scripts/oracle23ai.sh start

# 2. Install the schema
docker exec -w /opt/oracle/schemas/cikgu oracle23ai \
  sqlplus system/admin123@//localhost:1521/FREEPDB1 @cikgu_install.sql

# 3. Run the app
cd src/cikgu-app-django
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python manage.py runserver
```

Open **http://localhost:8000** and log in with any seeded account — password
`password123` for all of them (e.g. `halim.abdullah@cikgu.my`). Full
instructions, troubleshooting, and login options are in
[`docs/index.html`](docs/index.html).

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

Full column-level detail: [`schema/cikgu/data_dictionary.md`](../../schema/cikgu/data_dictionary.md).

## Scope

| In scope | Out of scope |
|---|---|
| Web platform for learners and tutors | Payment/billing |
| Role-based registration (Learner / Tutor) | Live video conferencing |
| Learner goals, module browsing and enrollment | Native mobile app |
| Tutor mentorship hierarchy, co-teaching | Resume parsing / AI features |
| Progress tracking and reporting dashboard | Automated assessment scoring |
| SQL-based reports and 10+ ad hoc queries | Session scheduling, production hosting |
