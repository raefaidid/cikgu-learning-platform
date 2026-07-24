# Prompt for Fable — Cikgu Personalized Learning Platform

Copy everything below the line into Fable as a single prompt.

> **Historical record.** This is the prompt originally used to generate the
> project's first implementation (Java/Spring Boot, per the "hard
> constraints" below). That implementation was later replaced with a
> Python/Django rewrite — see [`TECHNICAL_GUIDE.html`](TECHNICAL_GUIDE.html)
> and `src/cikgu-app-django/` for what's actually in the repo today. Kept
> here unedited as a record of the original database design brief, which is
> still accurate — only the application layer changed.

---

You are building the implementation for a university database engineering course project: **Cikgu, a Personalized Learning Platform**. The course (ICT502 Database Engineering, UiTM) grades the **database design and implementation**, not general software polish — read the constraints below carefully, they come directly from the grading rubric.

## Repo context

You are working inside an existing git repo (`database-engineering`). Root-level layout you must reuse, not duplicate:

- `docker-compose.yml`, `.env.example`, `scripts/oracle23ai.sh` — already run **Oracle Database 23ai Free** in Docker, exposed at `localhost:1521`, service `FREEPDB1`. Start it with `./scripts/oracle23ai.sh start`. Do not introduce a second database engine or a different Oracle setup.
- `schema/human_resources/` — an existing sample schema (`hr_install.sql`, `hr_create.sql`, `hr_populate.sql`, `hr_uninstall.sql`, `README.md`) that shows the house style for schema scripts: SQL*Plus scripts, a `SYSTEM`-run installer that creates a dedicated Oracle user/schema, `rem`-style header comments, lowercase table/column names. Mirror this style for the new schema, but simplify the installer to be non-interactive (no `ACCEPT`/prompts) since this is a course project, not a distributed sample schema.
- `projects/ICT502_GROUP/` — this project's home. `docs/` holds the graded proposal and rubrics (for your reference, not to be edited). `src/` is currently empty — that's where the application code goes.

Create your work in exactly these two places:

```
schema/cikgu/
  cikgu_install.sql       -- creates a CIKGU database user + grants (CREATE SESSION, RESOURCE, etc.), non-interactive
  cikgu_create.sql        -- DDL: tables, sequences, triggers, indexes, at least one view
  cikgu_populate.sql      -- DML: seed data
  cikgu_queries.sql       -- the 10 ad hoc queries (see below), each with a comment stating the question
  cikgu_uninstall.sql     -- drops the CIKGU user/schema
  data_dictionary.md      -- table/column/type/constraint/description for every table
  README.md               -- install/run instructions, mirroring schema/human_resources/README.md

projects/ICT502_GROUP/src/cikgu-app/
  pom.xml
  src/main/java/...
  src/main/resources/application.properties
  src/main/resources/templates/
```

## Hard constraints (do not deviate)

- **Database must be Oracle** (the existing 23ai Free container). No SQLite/Postgres/MySQL, even for local dev convenience.
- **Backend: Java, Spring Boot.** Use Spring MVC + Thymeleaf server-rendered views (no separate SPA/frontend build step — keep it simple to run and demo). Use **Spring JDBC (`JdbcTemplate`/`NamedParameterJdbcTemplate`)** for all data access, **not** Spring Data JPA/Hibernate. Hand-written SQL is required here — the course report needs literal DDL/DML appendices, and an ORM auto-generating schema would drift from the design below. Use Spring Security for session-based authentication.
- Use the **ojdbc11** Oracle JDBC driver and Maven.
- No payment/billing, no live video conferencing, no native mobile app, no resume parsing, no automated assessment scoring engine, no session-scheduling calendar, no production deployment/hosting concerns. Keep the app runnable locally only, against the existing Docker Oracle container.

## Database design (build exactly this — 7 tables)

Note: the entity called `USER` in the original proposal is renamed **`APP_USER`** here because `USER` collides with an Oracle built-in pseudo-column.

```
APP_USER
  user_id         NUMBER          PK, populated via sequence + trigger (CIKGU_USER_SEQ)
  full_name       VARCHAR2(150)   NOT NULL
  email           VARCHAR2(150)   NOT NULL, UNIQUE
  password_hash   VARCHAR2(255)   NOT NULL   -- BCrypt hash, never store plaintext
  phone           VARCHAR2(30)
  date_joined     DATE            NOT NULL DEFAULT SYSDATE
  user_type       VARCHAR2(10)    NOT NULL CHECK (user_type IN ('LEARNER','TUTOR'))

LEARNER   -- disjoint specialization of APP_USER
  user_id               NUMBER PK, FK -> APP_USER(user_id) ON DELETE CASCADE
  education_background  VARCHAR2(500)
  parsed_skills         VARCHAR2(1000)

TUTOR     -- disjoint specialization of APP_USER
  user_id           NUMBER PK, FK -> APP_USER(user_id) ON DELETE CASCADE
  mentor_id         NUMBER NULL, FK -> TUTOR(user_id) ON DELETE SET NULL   -- recursive: senior tutor mentors junior tutor
  expertise         VARCHAR2(300)
  years_experience  NUMBER(3) CHECK (years_experience >= 0)

GOAL
  goal_id         NUMBER PK, sequence CIKGU_GOAL_SEQ
  user_id         NUMBER NOT NULL, FK -> LEARNER(user_id)
  goal_title      VARCHAR2(200) NOT NULL
  target_outcome  VARCHAR2(500)
  target_date     DATE

MODULE
  module_id        NUMBER PK, sequence CIKGU_MODULE_SEQ
  module_title     VARCHAR2(200) NOT NULL
  description      VARCHAR2(1000)
  duration_hours   NUMBER(5) CHECK (duration_hours > 0)
  difficulty       VARCHAR2(20) CHECK (difficulty IN ('BEGINNER','INTERMEDIATE','ADVANCED'))
  -- deliberately NO direct tutor FK here -- see MODULE_TUTOR below

MODULE_TUTOR   -- bridge: resolves MODULE <-> TUTOR many-to-many (co-teaching)
  module_id      NUMBER, FK -> MODULE(module_id)
  user_id        NUMBER, FK -> TUTOR(user_id)
  PRIMARY KEY (module_id, user_id)
  teaching_role  VARCHAR2(15) NOT NULL DEFAULT 'LEAD' CHECK (teaching_role IN ('LEAD','CO_TEACHER'))
  assigned_date  DATE DEFAULT SYSDATE
  -- enforce exactly one LEAD per module, e.g. via a trigger or a function-based unique index
  -- on module_id where teaching_role = 'LEAD'

ENROLLMENT   -- bridge: resolves LEARNER <-> MODULE many-to-many, guided by a GOAL
  user_id          NUMBER, FK -> LEARNER(user_id)
  module_id        NUMBER, FK -> MODULE(module_id)
  PRIMARY KEY (user_id, module_id)
  goal_id          NUMBER NULL, FK -> GOAL(goal_id)   -- non-key FK; "this enrollment is guided by this goal"
  enroll_date      DATE NOT NULL DEFAULT SYSDATE
  progress_score   NUMBER(5,2) DEFAULT 0 CHECK (progress_score BETWEEN 0 AND 100)
  status           VARCHAR2(20) NOT NULL DEFAULT 'NOT_STARTED'
                   CHECK (status IN ('NOT_STARTED','IN_PROGRESS','COMPLETED','DROPPED'))
  last_updated_at  TIMESTAMP   -- set by a BEFORE UPDATE trigger every time the row changes
```

Design elements the schema must visibly demonstrate (these map directly to graded ERD/report criteria — do not simplify them away):

- **Inheritance / disjoint specialization**: `APP_USER` is the superclass; `LEARNER` and `TUTOR` are subclasses keyed off `user_type`.
- **Recursive relationship**: `TUTOR.mentor_id` self-references `TUTOR.user_id`.
- **Two bridge/associative entities**: `ENROLLMENT` (LEARNER×MODULE, carrying `goal_id`) and `MODULE_TUTOR` (MODULE×TUTOR, carrying `teaching_role`). `MODULE_TUTOR` is a deliberate fix to the original 1-tutor-per-module design, which the course lecturer flagged as questionable on the graded proposal — modules can now have co-teachers.
- **Sequence-based primary keys** on every surrogate PK (`CIKGU_USER_SEQ`, `CIKGU_GOAL_SEQ`, `CIKGU_MODULE_SEQ`), each with a `BEFORE INSERT` trigger populating the PK from `NEXTVAL` (do not use `IDENTITY` columns — sequences are what the course explicitly credits).
- Indexes on FK columns not already covered by a PK/unique index: `goal.user_id`, `tutor.mentor_id`, `enrollment.goal_id`, `module_tutor.user_id`.
- At least one `CREATE VIEW` summarizing enrollment/progress data for the reporting dashboard.
- A `BEFORE UPDATE` trigger on `ENROLLMENT` maintaining `last_updated_at`.

Business rules to enforce (via constraints/triggers, not just app-layer validation where practical):

1. A USER is either a LEARNER or a TUTOR, determined by `user_type`.
2. A LEARNER can define many GOALs; each GOAL belongs to exactly one LEARNER.
3. A TUTOR can mentor many TUTORs; each TUTOR has at most one mentor.
4. A TUTOR can teach many MODULEs and a MODULE can have many TUTORs (co-teaching via `MODULE_TUTOR`), but exactly one of them is the `LEAD` for that module.
5. A LEARNER can enroll in many MODULEs and a MODULE can have many LEARNERs enrolled, via `ENROLLMENT`.
6. Each ENROLLMENT is optionally guided by one GOAL.

## Application functionality

**Registration/auth**: a single registration form where the user picks LEARNER or TUTOR; the handler must insert the `APP_USER` row and the matching subclass row inside **one Spring `@Transactional` method** (commit only if both succeed — this is an explicit demonstration of transaction management, a topic covered in the course). Passwords BCrypt-hashed. Session-based login via Spring Security. Learner and Tutor accounts see different navigation/menus after login.

**Learner-facing screens**:
- Dashboard: their goals, their enrollments, progress at a glance.
- Goal management: create, edit, delete goals.
- Browse/search modules (read-only list, with filter by difficulty).
- Enroll in a module, optionally linking the enrollment to one of their goals.
- View their own progress/status per enrollment (read-only; tutors update it).

**Tutor-facing screens**:
- Dashboard: modules they lead or co-teach, and their mentees if they are a senior tutor.
- Module management: create, edit, delete modules.
- Manage co-teachers on a module: add/remove rows in `MODULE_TUTOR` (this is the second bridge-entity CRUD screen — keep it visually distinct from the enrollment screen).
- Update `progress_score`/`status` for learners enrolled in modules they teach.
- Mentor/mentee hierarchy view: show the full reporting chain using an Oracle `CONNECT BY PRIOR` recursive query (not just a single-level join) — this is the recursive-relationship demo screen.

**Reports/dashboard** (answers the project's own stated problem — tutors currently can't answer "who's behind schedule" or "what modules perform best" without manual spreadsheet work):
- Top-performing modules: average `progress_score` per module, ranked.
- Learners behind schedule: enrollments where the linked goal's `target_date` has passed but `status != 'COMPLETED'`.
- Render at least one of these as a simple chart (e.g. Chart.js) rather than only a table.

**Ad hoc SQL query console**: an authenticated page (available to both roles) where a user can type and run a **read-only `SELECT` statement** against the schema and see tabular results. Reject any input that isn't a single `SELECT` (simple keyword/statement-type guard is sufficient — this does not need to be bulletproof against a malicious DBA-level user, just prevent accidental/casual DML from this console). This screen exists so each team member can run their own ad hoc query live during the presentation, and counts as one of the "extra feature" credits.

**CRUD coverage** — the course grades Insert/Read/Update/Delete/Bridge/Recursive/Inheritance as *separate* line items, each needing its own visible screen or action:
- Insert: registration, create goal, create module, enroll in module, add co-teacher
- Read: browse modules, view goals, dashboards, reports
- Update: edit goal, edit module, update enrollment progress/status, edit profile
- Delete: delete goal, drop/cancel enrollment, remove co-teacher
- Bridge: the enrollment screen and the co-teacher assignment screen
- Recursive: mentor assignment (setting a tutor's `mentor_id`) and the mentor/mentee hierarchy view
- Inheritance: registration flow (creating `APP_USER` + subclass together) and a profile page that joins both
- Extra: sequence-based PKs, the `last_updated_at` trigger, the reporting view, the query console, the dashboard chart

## Seed data

Populate 15-30 rows per table (not just the rubric's bare minimum of 2), enough that the aggregate reports (top modules, behind-schedule learners) produce visually meaningful, non-trivial results. Include at least: a multi-level tutor mentorship chain (3+ levels), at least one module with two co-teachers, and a mix of enrollment statuses/progress scores across learners.

## The 10 ad hoc queries (`cikgu_queries.sql`)

Write these as commented, standalone SQL statements — the course report needs 10 queries of *visibly different kinds* (repeating the same query shape with different literals only earns partial credit):

1. Simple filter — tutors with `years_experience > 5`
2. Multi-table join — learner name + enrolled module title + progress score
3. Aggregate + `GROUP BY`/`ORDER BY` — average progress per module, descending
4. Subquery with `NOT EXISTS` — learners with zero enrollments
5. `CONNECT BY PRIOR` recursive — full mentor → mentee chain
6. `GROUP BY` + `HAVING` — modules with more than N enrollments
7. Analytic/window function — `RANK()` of learners by progress within each module
8. `INSERT` — add a new goal for a learner
9. `UPDATE` — mark enrollments `COMPLETED` where `progress_score >= 100`
10. `DELETE` — purge `DROPPED` enrollments older than a cutoff date

## Deliverables checklist (map directly to the report's appendices)

- [ ] `schema/cikgu/cikgu_install.sql` — creates the CIKGU Oracle user + grants
- [ ] `schema/cikgu/cikgu_create.sql` — all DDL (tables, sequences, triggers, indexes, view)
- [ ] `schema/cikgu/cikgu_populate.sql` — seed DML
- [ ] `schema/cikgu/cikgu_queries.sql` — the 10 queries above, each with a comment stating the question it answers
- [ ] `schema/cikgu/cikgu_uninstall.sql`
- [ ] `schema/cikgu/data_dictionary.md`
- [ ] `schema/cikgu/README.md` — install/run instructions, following `schema/human_resources/README.md`'s structure
- [ ] Working Spring Boot app under `projects/ICT502_GROUP/src/cikgu-app/`, runnable with `mvn spring-boot:run` against the existing Docker Oracle container

## Definition of done

1. `./scripts/oracle23ai.sh start` brings up Oracle; the `cikgu_*.sql` scripts install cleanly against `FREEPDB1` the same way the existing HR schema does.
2. `mvn spring-boot:run` starts the app; you can register as a Learner and as a Tutor, create a goal, browse and enroll in a module, have a tutor assign a co-teacher and update a learner's progress, view the mentor hierarchy, view the reports dashboard, and run at least one query in the ad hoc console — all without errors.
3. Every item in the CRUD-coverage checklist above corresponds to an actual clickable screen/action in the running app.
