# Cikgu — Technical Guide

This guide is for the group (NBCS2306A – Group 3) to understand, run, and demo the
Cikgu system, **even if you have never touched Oracle, Spring Boot, or Docker
before.** Read top to bottom the first time; after that, use it as a reference.

It covers three things:

1. **The tech stack**, explained in plain language.
2. **How to get the system running** on your own laptop.
3. **A page-by-page walkthrough**, mapped to what the presentation rubric actually
   grades, with a suggested demo script.

If you only have 10 minutes before the presentation, skip to
[§4 Demo script](#4-demo-script-for-the-presentation).

---

## 1. The tech stack, explained

Cikgu is a normal **three-layer web application**: a browser talks to a Java
web server, which talks to an Oracle database. Nothing runs "in the cloud" —
everything runs on your own machine.

```
┌─────────────┐        HTTP         ┌──────────────────┐       JDBC        ┌───────────────┐
│   Browser   │  ───────────────▶   │  Spring Boot app  │  ───────────────▶ │ Oracle Database │
│ (Chrome...) │  ◀───────────────   │  (Java, port 8080) │  ◀─────────────── │ (Docker, 1521)  │
└─────────────┘     HTML pages      └──────────────────┘   rows / SQL       └───────────────┘
```

| Piece | What it is | Why we use it here |
|---|---|---|
| **Oracle Database 23ai** | The relational database itself — where every table, sequence, trigger and view actually lives. | The course rubric *requires* Oracle. |
| **Docker** | A tool that runs Oracle in an isolated "container" instead of installing it directly on your Mac/PC. | Lets everyone on the team run the *exact same* database with one command, no manual Oracle install. |
| **Java 21** | The programming language the web app is written in. | Course-approved language; strongly typed, good Oracle driver support. |
| **Maven** | Java's build tool — downloads libraries and compiles/runs the project. | Standard for Java projects; one command builds everything. |
| **Spring Boot** | A framework that wires together a web server, security, and database access without needing tons of boilerplate. | Industry-standard way to build a Java web app quickly. |
| **Spring MVC** | The part of Spring Boot that turns a URL like `/learner/goals` into Java code that decides what page to show. | Standard request-routing pattern (Model-View-Controller). |
| **Thymeleaf** | A template engine — lets us write `.html` files with placeholders (like `${goal.title}`) that Spring fills in with real data before sending the page to the browser. | No separate frontend build step (no React/npm) — keeps the project simple to run and grade. |
| **Spring JDBC (`JdbcTemplate`)** | The library we use to run SQL and map result rows into Java objects. | **We deliberately do NOT use an ORM (like Hibernate/JPA).** Every query is hand-written SQL, because the course grades your literal DDL/DML — an ORM would auto-generate SQL that doesn't match your report. |
| **Spring Security** | Handles login, logout, sessions, and page access rules (e.g. "only tutors can see `/tutor/**`"). | Off-the-shelf, well-tested auth instead of writing our own. |
| **ojdbc11** | Oracle's official JDBC driver — the library that lets Java talk to Oracle over the network. | Required to connect Java to Oracle at all. |
| **Chart.js** | A small JavaScript charting library, loaded from a local file (no internet needed). | Satisfies the "extra feature" / graph requirement in the rubric. |
| **BCrypt** | A one-way password hashing algorithm. | Passwords are never stored as plain text — a basic security requirement. |

**You do not need to be a Java expert to demo this.** You need to know: how to
start Oracle, how to start the app, and what each page proves about the
database design.

---

## 2. Project layout

```
database-engineering/
├── docker-compose.yml, scripts/oracle23ai.sh   ← starts Oracle in Docker
├── schema/
│   ├── human_resources/                        ← lecturer's sample schema (ignore)
│   └── cikgu/                                   ← OUR database: DDL, seed data, 10 queries
│       ├── cikgu_install.sql                    ← run this first (creates everything)
│       ├── cikgu_create.sql                     ← tables, sequences, triggers, view
│       ├── cikgu_populate.sql                   ← seed/demo data
│       ├── cikgu_queries.sql                    ← the 10 ad hoc queries for the report
│       ├── cikgu_uninstall.sql                  ← wipes the schema clean
│       ├── data_dictionary.md                   ← Appendix B material
│       └── README.md                            ← schema-only install instructions
└── projects/ICT502_GROUP/
    ├── docs/                                    ← this guide, rubrics, proposal, report
    └── src/cikgu-app/                           ← OUR web application (Java/Spring Boot)
        ├── pom.xml                              ← Maven project file (dependencies)
        └── src/main/
            ├── java/com/cikgu/
            │   ├── controller/   ← handles URLs, decides what page to show
            │   ├── service/      ← business logic that needs a transaction
            │   ├── repository/   ← all the hand-written SQL lives here
            │   ├── model/        ← plain Java objects that hold a row of data
            │   └── security/     ← login/session wiring
            └── resources/
                ├── application.properties       ← DB connection settings
                ├── templates/                    ← the actual HTML pages (Thymeleaf)
                └── static/css, static/js         ← styling + Chart.js
```

**Rule of thumb while reading code:** a `Controller` receives a URL, a
`Repository` runs SQL, and a `template` (`.html` file) renders the result.
`Service` classes only exist where a screen must do more than one database
write atomically (see §4, "transaction demo").

---

## 3. Running it on your own machine

### 3.1 Prerequisites (install once)

- **Docker Desktop** — running Oracle.
- **Java 21** (check with `java -version`).
- **Maven** (check with `mvn -version`).

### 3.2 Start the database

From the **repository root** (`database-engineering/`):

```bash
./scripts/oracle23ai.sh start
```

First start can take a few minutes (Oracle is initializing). Check it's ready:

```bash
docker ps
# oracle23ai ... (healthy)   ← wait for "healthy"
```

### 3.3 Install the Cikgu schema (only needed once, or after a reset)

```bash
docker exec -w /opt/oracle/schemas/cikgu oracle23ai \
  sqlplus system/admin123@//localhost:1521/FREEPDB1 @cikgu_install.sql
```

(`admin123` is the password in the repo's `.env` file — check that file if it
was changed.) This **drops and recreates** the `CIKGU` schema and reloads all
seed data — safe to re-run any time you want a clean demo dataset.

If you ever want to wipe the schema entirely:

```bash
docker exec -w /opt/oracle/schemas/cikgu oracle23ai \
  sqlplus system/admin123@//localhost:1521/FREEPDB1 @cikgu_uninstall.sql
```

### 3.4 Run the web app

```bash
cd projects/ICT502_GROUP/src/cikgu-app
mvn spring-boot:run
```

Wait for a line like `Started CikguApplication in N.NNN seconds`, then open:

**http://localhost:8080**

> **Port 8080 already in use?** Something else on your machine (e.g. GlassFish,
> Tomcat, another project) is holding it. Either stop that other server, or
> run Cikgu on a different port:
> `mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8081`

### 3.5 Log in

Every seeded account uses the password **`password123`**. A few useful ones:

| Email | Role | Notable for demo |
|---|---|---|
| `halim.abdullah@cikgu.my` | Tutor | Top of the mentorship chain, leads *SQL Fundamentals* with 2 co-teachers |
| `salmah.yusof@cikgu.my` | Tutor | Mentored by Halim, leads *Advanced PL/SQL* |
| `aina.sofea@cikgu.my` | Learner | Has 2 goals and 3 enrollments (one completed, one behind schedule) |
| `wong.kaixin@cikgu.my` | Learner | Has a goal but **zero enrollments** (useful if demoing the "learners with no enrollment" query) |

You can also just click **Register** and create your own account live — this
is actually a good thing to show in the presentation (see §4).

---

## 4. Page-by-page walkthrough

Every screen below exists because it is graded by name in the rubric
(**Insert / Read / Update / Delete / Bridge / Recursive / Inheritance / Extra**,
20 marks) or the **System Presentation** (30 marks) and **ERD Understanding**
(5 marks) items. Use this table both to understand the code and as your demo
checklist.

### Public pages (no login)

| Page | URL | What it does | Rubric tie-in |
|---|---|---|---|
| Login | `/login` | Spring Security session login. | — |
| Register | `/register` | One form, pick **Learner** or **Tutor**. On submit, `RegistrationService.register()` inserts the `APP_USER` row **and** the matching `LEARNER`/`TUTOR` row inside a single `@Transactional` method — if either insert fails, both roll back. | **Insert**, **Inheritance**, transaction management |

### Learner pages (log in as a Learner)

| Page | URL | What it does | Rubric tie-in |
|---|---|---|---|
| Dashboard | `/learner/dashboard` | Summary tiles (goal count, enrollment count, completed, behind-schedule) plus a snapshot of goals and progress. | **Read** |
| My Goals | `/learner/goals` | Create a goal (title, outcome, target date); edit or delete existing ones. | **Insert / Update / Delete** on `GOAL` |
| Browse Modules | `/learner/modules` | Search by title, filter by difficulty; shows each module's LEAD tutor (pulled via `MODULE_TUTOR`). Enroll here, optionally linking the enrollment to one of your goals. | **Read**, **Bridge #1** (`ENROLLMENT`) |
| My Enrollments | `/learner/enrollments` | Your progress bars, status badges, linked goal, and a "BEHIND" flag if the goal's target date has passed. Cancel (delete) an enrollment here. | **Read**, **Delete** |
| Profile | `/profile` | Shows + edits your `app_user` row joined with your `learner` row (education background, skills). | **Inheritance** (superclass+subclass join) |

### Tutor pages (log in as a Tutor)

| Page | URL | What it does | Rubric tie-in |
|---|---|---|---|
| Dashboard | `/tutor/dashboard` | Modules you lead/co-teach, plus your **direct mentees** (one level of the recursive relationship). | **Read** |
| My Modules | `/tutor/modules` | Create a module (you become its `LEAD` automatically — see `ModuleService.createModule()`, another one-transaction demo); edit or delete a module you teach. | **Insert / Update / Delete** on `MODULE` |
| Co-teachers | `/tutor/modules/{id}/teachers` | Add/remove **co-teachers** on a module you lead. The database enforces **exactly one LEAD per module** via a function-based unique index — try adding a second LEAD from the SQL console (§5) to *prove* this live. | **Bridge #2** (`MODULE_TUTOR`) |
| Learner Progress | `/tutor/progress` | Update `progress_score` / `status` for every learner enrolled in a module you teach. Saving fires a **database trigger** that stamps `last_updated_at` — you don't write that column from Java at all. | **Update**, trigger demo |
| Mentorship | `/tutor/mentorship` | Full mentor→mentee tree via Oracle `CONNECT BY PRIOR` (not a single-level join — the *whole* chain, indented by depth). Below it, assign/change **your own** mentor; the dropdown excludes anyone in your own mentee subtree so you can't create a cycle. | **Recursive relationship** |

### Shared pages (either role)

| Page | URL | What it does | Rubric tie-in |
|---|---|---|---|
| Reports | `/reports` | Top-performing modules (avg. progress, ranked) as a bar chart + table; learners behind schedule as a table. Both read from the `module_progress_v` view. | **Extra** (view + chart), answers the platform's own problem statement |
| SQL Console | `/console` | Type and run **any single `SELECT`** against the schema; results render as a table (capped at 200 rows). Rejects anything that isn't a lone SELECT (no `;`, no INSERT/UPDATE/DELETE/DROP/etc.). | **ADHOC Query (10 marks)** — this is where each member runs their own individual query live |

---

## 5. Where the graded SQL artifacts live

For the **final report appendices**:

| Rubric appendix | File |
|---|---|
| Data Dictionary | `schema/cikgu/data_dictionary.md` |
| DDL (tables, sequences, triggers, view) | `schema/cikgu/cikgu_create.sql` |
| DML (seed data) | `schema/cikgu/cikgu_populate.sql` |
| 10 ad hoc queries | `schema/cikgu/cikgu_queries.sql` — each has a comment stating the question it answers, and covers 10 *different* SQL techniques (filter, join, aggregate, `NOT EXISTS`, `CONNECT BY PRIOR`, `HAVING`, window function, INSERT, UPDATE, DELETE) so nobody loses marks for "repeated SQL" |

To run all 10 queries and see their output for screenshots:

```bash
docker exec -w /opt/oracle/schemas/cikgu oracle23ai \
  sqlplus cikgu/Cikgu_123@//localhost:1521/FREEPDB1 @cikgu_queries.sql
```

(Queries 8–10 are INSERT/UPDATE/DELETE demos; the script rolls them back at
the end, so re-running it never corrupts your seed data.)

---

## 6. Demo script for the presentation

The **System Presentation** item (30 marks) explicitly rewards: the main
function working comprehensively, navigation working, and extra features
(graphs, Java). The **ERD Understanding** item (5 marks) rewards relating the
ERD to the *running system* while you explain it — not just reading the
diagram. Suggested order, roughly 10–12 minutes, one member per numbered
section works well for a 5-person group:

1. **Registration + inheritance** (~1 min) — Register a new Tutor live. Point
   at the ERD: "this one form writes to both `APP_USER` and `TUTOR` in one
   transaction — that's the disjoint specialization."
2. **Goals + browse + enroll** (~2 min) — As a learner, create a goal, browse
   modules filtered by difficulty, enroll in one linked to that goal. Point at
   the ERD: "`ENROLLMENT` is the bridge between `LEARNER` and `MODULE`, and it
   carries the goal link."
3. **Module + co-teacher management** (~2 min) — As a tutor, create a module
   (note you're auto-assigned LEAD), then add a co-teacher. Optionally, open
   the SQL console and try inserting a second LEAD row to show the unique
   index rejecting it — a nice unscripted "the database itself enforces this"
   moment.
4. **Progress update + trigger** (~1 min) — Update a learner's progress; point
   out `last_updated_at` changed even though nobody wrote to it explicitly.
5. **Mentorship hierarchy** (~2 min) — Show the full `CONNECT BY PRIOR` tree,
   then reassign a mentor and explain the recursive relationship.
6. **Reports** (~1 min) — Show the chart and the behind-schedule table; tie it
   back to the original problem statement ("tutors couldn't answer these
   questions without a spreadsheet — now it's one page").
7. **SQL console — one query per member** (~3–4 min) — This is where the
   **individual ad hoc query** marks come from. Each member should have their
   own query ready (don't all reuse the same one — the rubric explicitly
   rewards *different kinds* of SQL). Good picks from `cikgu_queries.sql`:
   the join, the `NOT EXISTS`, the `HAVING`, and the window function all look
   visually different and are easy to explain in 30 seconds.

**Before presenting:** run through §3 end-to-end on the machine you'll demo
from, at least once, so nobody is debugging Docker live in front of the
lecturer.
