# Cikgu Web Application

Spring Boot (Spring MVC + Thymeleaf + Spring JDBC + Spring Security) web app for the
**Cikgu Personalized Learning Platform** — ICT502 Database Engineering group project.
All data access is hand-written SQL through `JdbcTemplate` (no JPA/Hibernate), against
the `CIKGU` Oracle schema.

## Prerequisites

1. Java 21 and Maven.
2. The repository's Oracle 23ai Free container running: `./scripts/oracle23ai.sh start` (repo root).
3. The CIKGU schema installed — see `schema/cikgu/README.md`:

   ```
   docker exec -w /opt/oracle/schemas/cikgu oracle23ai \
     sqlplus system/<ORACLE_PWD>@//localhost:1521/FREEPDB1 @cikgu_install.sql
   ```

## Run

```
cd projects/ICT502_GROUP/src/cikgu-app
mvn spring-boot:run
```

Open <http://localhost:8080>. Log in with a seeded account (password `password123`
for all of them), e.g.:

| Email | Role |
|---|---|
| `halim.abdullah@cikgu.my` | Tutor (mentors several tutors, leads SQL Fundamentals) |
| `aina.sofea@cikgu.my` | Learner (goals + enrollments seeded) |

or register a fresh Learner/Tutor account.

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
| Transaction demo | `RegistrationService#register`, `ModuleService#createModule` |
| Trigger demo | Tutor → Learner Progress (updates stamp `last_updated_at`) |
| View demo | Reports page reads `module_progress_v` |
| Extra: SQL console | SQL Console (read-only SELECT, both roles) |
| Extra: chart | Reports page (Chart.js bar chart, served locally) |
