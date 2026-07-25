rem
rem NAME
rem   cikgu_uninstall.sql - Remove the CIKGU schema
rem
rem DESCRIPTION
rem   Drops the CIKGU database user and all of its objects.
rem
rem UNINSTALL INSTRUCTIONS
rem   Run as a privileged user with rights to drop another user
rem   (SYSTEM, ADMIN, etc.), connected to the FREEPDB1 pluggable database:
rem
rem      sqlplus system/<password>@//localhost:1521/FREEPDB1 @cikgu_uninstall.sql
rem
rem --------------------------------------------------------------------------

SET SERVEROUTPUT ON;

rem =======================================================
rem Drop the CIKGU user and all schema objects.
rem Use PL/SQL to avoid a "user does not exist" error.
rem =======================================================

DECLARE
   user_does_not_exist EXCEPTION;
   PRAGMA EXCEPTION_INIT(user_does_not_exist, -1918);
BEGIN
   EXECUTE IMMEDIATE 'DROP USER cikgu CASCADE';
   DBMS_OUTPUT.PUT_LINE('CIKGU schema has been dropped.');
EXCEPTION
   WHEN user_does_not_exist THEN
      DBMS_OUTPUT.PUT_LINE('CIKGU schema does not exist, no actions performed.');
END;
/

SET SERVEROUTPUT OFF;

--
-- Disconnect to prevent accidental commands as a privileged user.
--
disconnect
