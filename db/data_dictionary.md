# Cikgu Schema — Data Dictionary

Schema for the **Cikgu Personalized Learning Platform** (ICT502 Database Engineering group project). Oracle Database 23ai Free, schema owner `CIKGU`.

Design summary:

- **Inheritance / disjoint specialization** — `APP_USER` is the superclass; `LEARNER` and `TUTOR` are subclasses discriminated by `APP_USER.USER_TYPE`.
- **Recursive relationship** — `TUTOR.MENTOR_ID` references `TUTOR.USER_ID` (a senior tutor mentors junior tutors).
- **Bridge entities** — `ENROLLMENT` (LEARNER × MODULE, carries `GOAL_ID`) and `MODULE_TUTOR` (MODULE × TUTOR, carries `TEACHING_ROLE`).
- **Sequence-based surrogate keys** — `CIKGU_USER_SEQ`, `CIKGU_GOAL_SEQ`, `CIKGU_MODULE_SEQ`, each applied by a `BEFORE INSERT` trigger when no id is supplied.

---

## APP_USER

Superclass holding every platform account (learners and tutors).

| Column | Type | Constraints | Description |
|---|---|---|---|
| USER_ID | NUMBER | PK (`app_user_pk`); populated by `CIKGU_USER_SEQ` via trigger `app_user_bi_trg` | Surrogate key for every account |
| FULL_NAME | VARCHAR2(150) | NOT NULL | Person's full name |
| EMAIL | VARCHAR2(150) | NOT NULL, UNIQUE (`app_user_email_uk`) | Login identifier |
| PASSWORD_HASH | VARCHAR2(255) | NOT NULL | BCrypt hash of the password; plaintext is never stored |
| PHONE | VARCHAR2(30) | — | Contact number (optional) |
| DATE_JOINED | DATE | NOT NULL, DEFAULT SYSDATE | Registration date |
| USER_TYPE | VARCHAR2(10) | NOT NULL, CHECK IN ('LEARNER','TUTOR') (`app_user_type_ck`) | Disjoint specialization discriminator |

## LEARNER

Subclass of `APP_USER` for accounts with `USER_TYPE = 'LEARNER'`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| USER_ID | NUMBER | PK (`learner_pk`); FK → APP_USER(USER_ID) ON DELETE CASCADE (`learner_user_fk`) | Shared key with the superclass row |
| EDUCATION_BACKGROUND | VARCHAR2(500) | — | Prior education summary |
| PARSED_SKILLS | VARCHAR2(1000) | — | Comma-separated skills extracted from the learner's profile |

## TUTOR

Subclass of `APP_USER` for accounts with `USER_TYPE = 'TUTOR'`. Holds the recursive mentorship relationship.

| Column | Type | Constraints | Description |
|---|---|---|---|
| USER_ID | NUMBER | PK (`tutor_pk`); FK → APP_USER(USER_ID) ON DELETE CASCADE (`tutor_user_fk`) | Shared key with the superclass row |
| MENTOR_ID | NUMBER | NULL allowed; FK → TUTOR(USER_ID) ON DELETE SET NULL (`tutor_mentor_fk`); indexed (`tutor_mentor_ix`) | The senior tutor mentoring this tutor (recursive FK) |
| EXPERTISE | VARCHAR2(300) | — | Subject-matter expertise |
| YEARS_EXPERIENCE | NUMBER(3) | CHECK >= 0 (`tutor_years_ck`) | Years of teaching experience |

## GOAL

A learning goal defined by a learner; a learner can define many goals.

| Column | Type | Constraints | Description |
|---|---|---|---|
| GOAL_ID | NUMBER | PK (`goal_pk`); populated by `CIKGU_GOAL_SEQ` via trigger `goal_bi_trg` | Surrogate key |
| USER_ID | NUMBER | NOT NULL; FK → LEARNER(USER_ID) ON DELETE CASCADE (`goal_learner_fk`); indexed (`goal_user_ix`) | The learner who owns the goal |
| GOAL_TITLE | VARCHAR2(200) | NOT NULL | Short goal title |
| TARGET_OUTCOME | VARCHAR2(500) | — | What success looks like |
| TARGET_DATE | DATE | — | Deadline the learner aims for; drives the behind-schedule report |

## MODULE

A learning module (course unit). Tutors attach through `MODULE_TUTOR` — deliberately no direct tutor FK, so modules can be co-taught.

| Column | Type | Constraints | Description |
|---|---|---|---|
| MODULE_ID | NUMBER | PK (`module_pk`); populated by `CIKGU_MODULE_SEQ` via trigger `module_bi_trg` | Surrogate key |
| MODULE_TITLE | VARCHAR2(200) | NOT NULL | Module title |
| DESCRIPTION | VARCHAR2(1000) | — | What the module covers |
| DURATION_HOURS | NUMBER(5) | CHECK > 0 (`module_duration_ck`) | Estimated study hours |
| DIFFICULTY | VARCHAR2(20) | CHECK IN ('BEGINNER','INTERMEDIATE','ADVANCED') (`module_difficulty_ck`) | Difficulty tier used by the module browser filter |

## MODULE_TUTOR

Bridge entity resolving the MODULE ↔ TUTOR many-to-many relationship (co-teaching).

| Column | Type | Constraints | Description |
|---|---|---|---|
| MODULE_ID | NUMBER | Composite PK (`module_tutor_pk`); FK → MODULE(MODULE_ID) ON DELETE CASCADE (`modtut_module_fk`) | The module being taught |
| USER_ID | NUMBER | Composite PK; FK → TUTOR(USER_ID) ON DELETE CASCADE (`modtut_tutor_fk`); indexed (`modtut_tutor_ix`) | The tutor teaching it |
| TEACHING_ROLE | VARCHAR2(15) | NOT NULL, DEFAULT 'LEAD', CHECK IN ('LEAD','CO_TEACHER') (`modtut_role_ck`) | Role on this module |
| ASSIGNED_DATE | DATE | DEFAULT SYSDATE | When the tutor was assigned |

Business rule: **exactly one LEAD per module**, enforced by the function-based unique index `modtut_one_lead_uix` on `CASE WHEN teaching_role = 'LEAD' THEN module_id END`.

## ENROLLMENT

Bridge entity resolving the LEARNER ↔ MODULE many-to-many relationship; optionally guided by one GOAL.

| Column | Type | Constraints | Description |
|---|---|---|---|
| USER_ID | NUMBER | Composite PK (`enrollment_pk`); FK → LEARNER(USER_ID) ON DELETE CASCADE (`enroll_learner_fk`) | The enrolled learner |
| MODULE_ID | NUMBER | Composite PK; FK → MODULE(MODULE_ID) ON DELETE CASCADE (`enroll_module_fk`) | The module enrolled in |
| GOAL_ID | NUMBER | NULL allowed; FK → GOAL(GOAL_ID) ON DELETE SET NULL (`enroll_goal_fk`); indexed (`enroll_goal_ix`) | Non-key FK: the goal guiding this enrollment |
| ENROLL_DATE | DATE | NOT NULL, DEFAULT SYSDATE | Enrollment date |
| PROGRESS_SCORE | NUMBER(5,2) | DEFAULT 0, CHECK BETWEEN 0 AND 100 (`enroll_progress_ck`) | Progress percentage, maintained by tutors |
| STATUS | VARCHAR2(20) | NOT NULL, DEFAULT 'NOT_STARTED', CHECK IN ('NOT_STARTED','IN_PROGRESS','COMPLETED','DROPPED') (`enroll_status_ck`) | Enrollment lifecycle state |
| LAST_UPDATED_AT | TIMESTAMP | Maintained by trigger `enrollment_bu_trg` on every UPDATE | Audit timestamp of the last change |

---

## Sequences

| Sequence | Used by | Start | Notes |
|---|---|---|---|
| CIKGU_USER_SEQ | APP_USER.USER_ID | 1000 | Seed rows use ids 1–33 |
| CIKGU_GOAL_SEQ | GOAL.GOAL_ID | 1000 | Seed rows use ids 1–20 |
| CIKGU_MODULE_SEQ | MODULE.MODULE_ID | 1000 | Seed rows use ids 1–15 |

## Triggers

| Trigger | Table | Timing | Purpose |
|---|---|---|---|
| app_user_bi_trg | APP_USER | BEFORE INSERT | Fills USER_ID from CIKGU_USER_SEQ when NULL |
| goal_bi_trg | GOAL | BEFORE INSERT | Fills GOAL_ID from CIKGU_GOAL_SEQ when NULL |
| module_bi_trg | MODULE | BEFORE INSERT | Fills MODULE_ID from CIKGU_MODULE_SEQ when NULL |
| enrollment_bu_trg | ENROLLMENT | BEFORE UPDATE | Sets LAST_UPDATED_AT to SYSTIMESTAMP on every update |

## Indexes (beyond PK/unique indexes)

| Index | Table (columns) | Purpose |
|---|---|---|
| goal_user_ix | GOAL (USER_ID) | FK lookup: goals per learner |
| tutor_mentor_ix | TUTOR (MENTOR_ID) | FK lookup: mentees per mentor |
| enroll_goal_ix | ENROLLMENT (GOAL_ID) | FK lookup: enrollments per goal |
| modtut_tutor_ix | MODULE_TUTOR (USER_ID) | FK lookup: modules per tutor |
| modtut_one_lead_uix | MODULE_TUTOR (function-based) | Enforces exactly one LEAD per module |

## Views

| View | Purpose |
|---|---|
| MODULE_PROGRESS_V | One row per enrollment joining learner, module and goal, with a computed `BEHIND_SCHEDULE` flag (`'Y'` when the linked goal's target date has passed and the enrollment is not COMPLETED). Backs the reporting dashboard. |
