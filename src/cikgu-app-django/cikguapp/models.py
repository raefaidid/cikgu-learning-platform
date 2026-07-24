# Deliberately empty: no Django ORM models. All data access goes through
# hand-written SQL in cikguapp/db.py and cikguapp/repositories/, matching the
# Spring Boot app's JdbcTemplate-only design against the CIKGU schema (see
# schema/cikgu/cikgu_create.sql for the table/trigger/view definitions).
