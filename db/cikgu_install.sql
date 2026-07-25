rem
rem NAME
rem   cikgu_install.sql - Main installation script for the CIKGU schema
rem
rem DESCRIPTION
rem   CIKGU is the database schema for the "Cikgu" Personalized Learning
rem   Platform, the ICT502 Database Engineering group project (UiTM).
rem   It creates a dedicated CIKGU database user, then builds and
rem   populates the schema objects.
rem
rem SCHEMA DEPENDENCIES AND REQUIREMENTS
rem   This script calls cikgu_create.sql and cikgu_populate.sql
rem
rem INSTALL INSTRUCTIONS
rem   1. Run as a privileged user with rights to create another user
rem      (SYSTEM, ADMIN, etc.), connected to the FREEPDB1 pluggable database.
rem   2. This script is non-interactive: it drops any existing CIKGU user,
rem      recreates it with the password 'Cikgu_123', and installs the schema.
rem
rem   Example (inside the oracle23ai container):
rem      sqlplus system/<password>@//localhost:1521/FREEPDB1 @cikgu_install.sql
rem
rem UNINSTALL INSTRUCTIONS
rem   Run the cikgu_uninstall.sql script as the same privileged user.
rem
rem --------------------------------------------------------------------------

SET ECHO OFF
SET VERIFY OFF
SET HEADING OFF
SET FEEDBACK OFF

rem Exit setup script on any error
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT
PROMPT Installing the CIKGU (Personalized Learning Platform) schema.
PROMPT The entire installation will be logged into 'cikgu_install.log'.
PROMPT

rem =======================================================
rem Log installation process
rem =======================================================

SPOOL cikgu_install.log

rem =======================================================
rem cleanup old CIKGU schema, if found
rem =======================================================

SET SERVEROUTPUT ON;
DECLARE
   user_does_not_exist EXCEPTION;
   PRAGMA EXCEPTION_INIT(user_does_not_exist, -1918);
BEGIN
   EXECUTE IMMEDIATE 'DROP USER cikgu CASCADE';
   DBMS_OUTPUT.PUT_LINE('Old CIKGU schema has been dropped.');
EXCEPTION
   WHEN user_does_not_exist THEN
      DBMS_OUTPUT.PUT_LINE('No existing CIKGU schema found, continuing.');
END;
/
SET SERVEROUTPUT OFF;

rem =======================================================
rem create the CIKGU schema user
rem (in the database's default permanent tablespace)
rem =======================================================

COLUMN property_value NEW_VALUE var_default_tablespace NOPRINT
SELECT property_value FROM database_properties
 WHERE property_name = 'DEFAULT_PERMANENT_TABLESPACE';

CREATE USER cikgu IDENTIFIED BY "Cikgu_123"
               DEFAULT TABLESPACE &var_default_tablespace
               QUOTA UNLIMITED ON &var_default_tablespace;

GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE SEQUENCE,
      CREATE TRIGGER,
      CREATE VIEW,
      CREATE PROCEDURE,
      CREATE SYNONYM
  TO cikgu;

ALTER SESSION SET CURRENT_SCHEMA=CIKGU;
ALTER SESSION SET NLS_LANGUAGE=American;
ALTER SESSION SET NLS_TERRITORY=America;
ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD';

rem =======================================================
rem create CIKGU schema objects
rem =======================================================

@@cikgu_create.sql

rem =======================================================
rem populate tables with data
rem =======================================================

@@cikgu_populate.sql

rem =======================================================
rem installation validation
rem =======================================================

SET HEADING ON
SET FEEDBACK OFF

SELECT 'Verification:' AS "Installation verification" FROM dual;

SELECT 'app_user'     AS "Table", count(1) AS "rows" FROM cikgu.app_user
UNION ALL
SELECT 'learner'      AS "Table", count(1) AS "rows" FROM cikgu.learner
UNION ALL
SELECT 'tutor'        AS "Table", count(1) AS "rows" FROM cikgu.tutor
UNION ALL
SELECT 'goal'         AS "Table", count(1) AS "rows" FROM cikgu.goal
UNION ALL
SELECT 'module'       AS "Table", count(1) AS "rows" FROM cikgu.module
UNION ALL
SELECT 'module_tutor' AS "Table", count(1) AS "rows" FROM cikgu.module_tutor
UNION ALL
SELECT 'enrollment'   AS "Table", count(1) AS "rows" FROM cikgu.enrollment;

SELECT 'The installation of the CIKGU schema is now finished.' AS "Done"
   FROM dual
UNION ALL
SELECT 'You will now be disconnected from the database.' AS "Done"
   FROM dual;

rem stop writing to the log file
SPOOL OFF

exit
