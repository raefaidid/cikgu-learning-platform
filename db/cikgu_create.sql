rem
rem NAME
rem   cikgu_create.sql - Create the CIKGU schema objects
rem
rem DESCRIPTION
rem   Creates the seven tables of the Cikgu Personalized Learning Platform,
rem   their sequences, triggers, indexes and the reporting view.
rem
rem   Design highlights (graded ERD criteria):
rem     - Inheritance / disjoint specialization:
rem         app_user (superclass) -> learner, tutor (subclasses via user_type)
rem     - Recursive relationship: tutor.mentor_id -> tutor.user_id
rem     - Bridge entities: enrollment (learner x module, carries goal_id)
rem       and module_tutor (module x tutor, carries teaching_role)
rem     - Sequence-based surrogate PKs populated by BEFORE INSERT triggers
rem     - BEFORE UPDATE trigger maintaining enrollment.last_updated_at
rem     - Function-based unique index enforcing exactly one LEAD per module
rem
rem --------------------------------------------------------------------------

SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 120
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

rem ********************************************************************
rem Create the APP_USER table: superclass of the disjoint specialization.
rem Named APP_USER because USER is an Oracle reserved word.

Prompt ******  Creating APP_USER table ....

CREATE TABLE app_user
    ( user_id        NUMBER
        CONSTRAINT app_user_id_nn NOT NULL
    , full_name      VARCHAR2(150)
        CONSTRAINT app_user_name_nn NOT NULL
    , email          VARCHAR2(150)
        CONSTRAINT app_user_email_nn NOT NULL
    , password_hash  VARCHAR2(255)
        CONSTRAINT app_user_pwd_nn NOT NULL
    , phone          VARCHAR2(30)
    , date_joined    DATE DEFAULT SYSDATE
        CONSTRAINT app_user_joined_nn NOT NULL
    , user_type      VARCHAR2(10)
        CONSTRAINT app_user_type_nn NOT NULL
    , CONSTRAINT app_user_pk PRIMARY KEY (user_id)
    , CONSTRAINT app_user_email_uk UNIQUE (email)
    , CONSTRAINT app_user_type_ck
        CHECK (user_type IN ('LEARNER','TUTOR'))
    );

rem ********************************************************************
rem Create the LEARNER table: subclass of APP_USER (user_type = LEARNER).

Prompt ******  Creating LEARNER table ....

CREATE TABLE learner
    ( user_id               NUMBER
        CONSTRAINT learner_id_nn NOT NULL
    , education_background  VARCHAR2(500)
    , parsed_skills         VARCHAR2(1000)
    , CONSTRAINT learner_pk PRIMARY KEY (user_id)
    , CONSTRAINT learner_user_fk FOREIGN KEY (user_id)
        REFERENCES app_user (user_id) ON DELETE CASCADE
    );

rem ********************************************************************
rem Create the TUTOR table: subclass of APP_USER (user_type = TUTOR).
rem tutor.mentor_id is the recursive relationship: a senior tutor
rem mentors junior tutors.

Prompt ******  Creating TUTOR table ....

CREATE TABLE tutor
    ( user_id           NUMBER
        CONSTRAINT tutor_id_nn NOT NULL
    , mentor_id         NUMBER
    , expertise         VARCHAR2(300)
    , years_experience  NUMBER(3)
    , CONSTRAINT tutor_pk PRIMARY KEY (user_id)
    , CONSTRAINT tutor_user_fk FOREIGN KEY (user_id)
        REFERENCES app_user (user_id) ON DELETE CASCADE
    , CONSTRAINT tutor_mentor_fk FOREIGN KEY (mentor_id)
        REFERENCES tutor (user_id) ON DELETE SET NULL
    , CONSTRAINT tutor_years_ck CHECK (years_experience >= 0)
    );

rem ********************************************************************
rem Create the GOAL table: a learner defines many goals.

Prompt ******  Creating GOAL table ....

CREATE TABLE goal
    ( goal_id         NUMBER
        CONSTRAINT goal_id_nn NOT NULL
    , user_id         NUMBER
        CONSTRAINT goal_user_nn NOT NULL
    , goal_title      VARCHAR2(200)
        CONSTRAINT goal_title_nn NOT NULL
    , target_outcome  VARCHAR2(500)
    , target_date     DATE
    , CONSTRAINT goal_pk PRIMARY KEY (goal_id)
    , CONSTRAINT goal_learner_fk FOREIGN KEY (user_id)
        REFERENCES learner (user_id) ON DELETE CASCADE
    );

rem ********************************************************************
rem Create the MODULE table. Deliberately no direct tutor FK here:
rem tutors are attached through the MODULE_TUTOR bridge (co-teaching).

Prompt ******  Creating MODULE table ....

CREATE TABLE module
    ( module_id       NUMBER
        CONSTRAINT module_id_nn NOT NULL
    , module_title    VARCHAR2(200)
        CONSTRAINT module_title_nn NOT NULL
    , description     VARCHAR2(1000)
    , duration_hours  NUMBER(5)
    , difficulty      VARCHAR2(20)
    , CONSTRAINT module_pk PRIMARY KEY (module_id)
    , CONSTRAINT module_duration_ck CHECK (duration_hours > 0)
    , CONSTRAINT module_difficulty_ck
        CHECK (difficulty IN ('BEGINNER','INTERMEDIATE','ADVANCED'))
    );

rem ********************************************************************
rem Create the MODULE_TUTOR bridge table: resolves the MODULE <-> TUTOR
rem many-to-many relationship (co-teaching). Exactly one LEAD per module
rem is enforced by the function-based unique index further below.

Prompt ******  Creating MODULE_TUTOR table ....

CREATE TABLE module_tutor
    ( module_id      NUMBER
        CONSTRAINT modtut_module_nn NOT NULL
    , user_id        NUMBER
        CONSTRAINT modtut_tutor_nn NOT NULL
    , teaching_role  VARCHAR2(15) DEFAULT 'LEAD'
        CONSTRAINT modtut_role_nn NOT NULL
    , assigned_date  DATE DEFAULT SYSDATE
    , CONSTRAINT module_tutor_pk PRIMARY KEY (module_id, user_id)
    , CONSTRAINT modtut_module_fk FOREIGN KEY (module_id)
        REFERENCES module (module_id) ON DELETE CASCADE
    , CONSTRAINT modtut_tutor_fk FOREIGN KEY (user_id)
        REFERENCES tutor (user_id) ON DELETE CASCADE
    , CONSTRAINT modtut_role_ck
        CHECK (teaching_role IN ('LEAD','CO_TEACHER'))
    );

rem ********************************************************************
rem Create the ENROLLMENT bridge table: resolves the LEARNER <-> MODULE
rem many-to-many relationship; optionally guided by one GOAL (non-key FK).

Prompt ******  Creating ENROLLMENT table ....

CREATE TABLE enrollment
    ( user_id          NUMBER
        CONSTRAINT enroll_user_nn NOT NULL
    , module_id        NUMBER
        CONSTRAINT enroll_module_nn NOT NULL
    , goal_id          NUMBER
    , enroll_date      DATE DEFAULT SYSDATE
        CONSTRAINT enroll_date_nn NOT NULL
    , progress_score   NUMBER(5,2) DEFAULT 0
    , status           VARCHAR2(20) DEFAULT 'NOT_STARTED'
        CONSTRAINT enroll_status_nn NOT NULL
    , last_updated_at  TIMESTAMP
    , CONSTRAINT enrollment_pk PRIMARY KEY (user_id, module_id)
    , CONSTRAINT enroll_learner_fk FOREIGN KEY (user_id)
        REFERENCES learner (user_id) ON DELETE CASCADE
    , CONSTRAINT enroll_module_fk FOREIGN KEY (module_id)
        REFERENCES module (module_id) ON DELETE CASCADE
    , CONSTRAINT enroll_goal_fk FOREIGN KEY (goal_id)
        REFERENCES goal (goal_id) ON DELETE SET NULL
    , CONSTRAINT enroll_progress_ck
        CHECK (progress_score BETWEEN 0 AND 100)
    , CONSTRAINT enroll_status_ck
        CHECK (status IN ('NOT_STARTED','IN_PROGRESS','COMPLETED','DROPPED'))
    );

rem ********************************************************************
rem Sequences for the surrogate primary keys. Seed data below uses
rem explicit ids 1..n, so the sequences start at 1000.

Prompt ******  Creating sequences ....

CREATE SEQUENCE cikgu_user_seq
 START WITH     1000
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

CREATE SEQUENCE cikgu_goal_seq
 START WITH     1000
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

CREATE SEQUENCE cikgu_module_seq
 START WITH     1000
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

rem ********************************************************************
rem BEFORE INSERT triggers populating each surrogate PK from its
rem sequence when the application does not supply an id.

Prompt ******  Creating PK triggers ....

CREATE OR REPLACE TRIGGER app_user_bi_trg
BEFORE INSERT ON app_user
FOR EACH ROW
WHEN (new.user_id IS NULL)
BEGIN
   :new.user_id := cikgu_user_seq.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER goal_bi_trg
BEFORE INSERT ON goal
FOR EACH ROW
WHEN (new.goal_id IS NULL)
BEGIN
   :new.goal_id := cikgu_goal_seq.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER module_bi_trg
BEFORE INSERT ON module
FOR EACH ROW
WHEN (new.module_id IS NULL)
BEGIN
   :new.module_id := cikgu_module_seq.NEXTVAL;
END;
/

rem ********************************************************************
rem BEFORE UPDATE trigger maintaining enrollment.last_updated_at on
rem every change to an enrollment row.

Prompt ******  Creating ENROLLMENT audit trigger ....

CREATE OR REPLACE TRIGGER enrollment_bu_trg
BEFORE UPDATE ON enrollment
FOR EACH ROW
BEGIN
   :new.last_updated_at := SYSTIMESTAMP;
END;
/

rem ********************************************************************
rem Indexes on foreign key columns not already covered by a PK or
rem unique index.

Prompt ******  Creating FK indexes ....

CREATE INDEX goal_user_ix     ON goal (user_id);
CREATE INDEX tutor_mentor_ix  ON tutor (mentor_id);
CREATE INDEX enroll_goal_ix   ON enrollment (goal_id);
CREATE INDEX modtut_tutor_ix  ON module_tutor (user_id);

rem ********************************************************************
rem Function-based unique index: at most one LEAD row per module.
rem (Rows with teaching_role = 'CO_TEACHER' map to NULL and are ignored.)

Prompt ******  Creating one-LEAD-per-module unique index ....

CREATE UNIQUE INDEX modtut_one_lead_uix
ON module_tutor (CASE WHEN teaching_role = 'LEAD' THEN module_id END);

rem ********************************************************************
rem Reporting view: one row per enrollment with learner, module, goal
rem and progress information, used by the reporting dashboard.

Prompt ******  Creating MODULE_PROGRESS_V view ....

CREATE OR REPLACE VIEW module_progress_v AS
SELECT e.user_id,
       au.full_name           AS learner_name,
       e.module_id,
       m.module_title,
       m.difficulty,
       e.goal_id,
       g.goal_title,
       g.target_date,
       e.enroll_date,
       e.progress_score,
       e.status,
       e.last_updated_at,
       CASE
          WHEN g.target_date < TRUNC(SYSDATE)
               AND e.status <> 'COMPLETED'
          THEN 'Y' ELSE 'N'
       END AS behind_schedule
  FROM enrollment e
  JOIN learner  l  ON l.user_id  = e.user_id
  JOIN app_user au ON au.user_id = l.user_id
  JOIN module   m  ON m.module_id = e.module_id
  LEFT JOIN goal g ON g.goal_id  = e.goal_id;

COMMIT;
