# Cikgu Schema

## Description

`CIKGU` is the database schema for the **Cikgu Personalized Learning Platform**, the ICT502 Database Engineering (UiTM) group project. It models learners pursuing learning goals, tutors (with a recursive mentorship hierarchy) co-teaching modules, and learner enrollments with progress tracking.

### Schema dependencies and requirements

`cikgu_install.sql` calls `cikgu_create.sql` and `cikgu_populate.sql`, so keep all three together.

Targets the **Oracle Database 23ai Free** container defined in this repository's `docker-compose.yml`, pluggable database `FREEPDB1` on `localhost:1521`. This `db/` directory is mounted into that container at `/opt/oracle/schemas/cikgu`.

## Install instructions

The setup script does everything below in one command — see the [repository README](../README.md). To do it by hand:

1. Start the database container from the repository root:

   ```
   docker compose up -d
   ```

   First start can take 3–10 minutes. Wait until the container reports `healthy`:

   ```
   docker ps
   ```

2. Run the installer as a privileged user (`SYSTEM`). The container's working
   directory is already this folder, so the script name needs no path:

   **macOS / Linux**

   ```bash
   docker compose exec -T oracle \
     sqlplus -S system/<ORACLE_PWD>@//localhost:1521/FREEPDB1 @cikgu_install.sql
   ```

   **Windows (PowerShell)** — note the quotes around both arguments:

   ```powershell
   docker compose exec -T oracle sqlplus -S "system/<ORACLE_PWD>@//localhost:1521/FREEPDB1" "@cikgu_install.sql"
   ```

   `<ORACLE_PWD>` is the value in this repository's `.env` file (`admin123` by default).

The installer is **non-interactive**: it drops any existing `CIKGU` user, recreates it with the password `Cikgu_123`, runs `cikgu_create.sql` and `cikgu_populate.sql`, and logs to `cikgu_install.log`.

**Note:** If the CIKGU schema already exists, it is dropped and a fresh CIKGU schema is installed. Re-running the installer is the fastest way to reset the demo data.

### Seeded accounts

Every seeded account (see `cikgu_populate.sql`) logs in to the web application with the password `password123`. Examples:

| Email | Role |
|---|---|
| `halim.abdullah@cikgu.my` | Tutor (top of the mentorship chain) |
| `salmah.yusof@cikgu.my` | Tutor |
| `aina.sofea@cikgu.my` | Learner |
| `priya.darshini@cikgu.my` | Learner |

## Running the ad hoc queries

Connect as the schema owner and run the 10 report queries:

```
docker compose exec -T oracle \
  sqlplus -S cikgu/Cikgu_123@//localhost:1521/FREEPDB1 @cikgu_queries.sql
```

Queries 8–10 are DML demonstrations and are rolled back at the end of the script, so the seed data is left unchanged.

## Uninstall instructions

```
docker compose exec -T oracle \
  sqlplus -S system/<ORACLE_PWD>@//localhost:1521/FREEPDB1 @cikgu_uninstall.sql
```

## Related application

The Django web application that uses this schema lives at [`../src/cikgu-app-django/`](../src/cikgu-app-django/) — see its README for run instructions.

## Files

| File | Purpose |
|---|---|
| `cikgu_install.sql` | Main installer: creates the CIKGU user, then runs create + populate |
| `cikgu_create.sql` | DDL: tables, sequences, triggers, indexes, reporting view |
| `cikgu_populate.sql` | Seed data (15–33 rows per table) |
| `cikgu_queries.sql` | The 10 ad hoc queries for the course report |
| `cikgu_uninstall.sql` | Drops the CIKGU user and all objects |
| `data_dictionary.md` | Column-level documentation for every table |
