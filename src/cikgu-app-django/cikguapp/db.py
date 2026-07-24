"""
Thin helpers over django.db.connection — the only data-access primitive this
app uses. Every query in cikguapp/repositories/ is hand-written SQL passed
straight to a cursor; nothing here builds SQL from a model. This mirrors the
Spring Boot app's JdbcTemplate usage against the same CIKGU schema.

Column names are lower-cased when building result dicts, since Oracle
upper-cases unquoted identifiers in cursor.description (e.g. "GOAL_TITLE")
and lower_snake_case reads naturally from both Python and Django templates.
"""

import datetime

from django.db import connection


def to_oracle_date(value):
    """
    oracledb binds datetime.datetime cleanly for Oracle DATE columns but not
    a bare datetime.date, so HTML date-input values (parsed to date objects)
    are lifted to midnight datetimes here before they hit a query.
    """
    if value is None:
        return None
    if isinstance(value, datetime.datetime):
        return value
    if isinstance(value, datetime.date):
        return datetime.datetime.combine(value, datetime.time.min)
    return value


def dictfetchall(cursor):
    columns = [col[0].lower() for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def dictfetchone(cursor):
    columns = [col[0].lower() for col in cursor.description]
    row = cursor.fetchone()
    return dict(zip(columns, row)) if row else None


def query_all(sql, params=None):
    """Run a SELECT, return a list of dicts."""
    with connection.cursor() as cursor:
        cursor.execute(sql, params or [])
        return dictfetchall(cursor)


def query_one(sql, params=None):
    """Run a SELECT expected to return at most one row; None if empty."""
    with connection.cursor() as cursor:
        cursor.execute(sql, params or [])
        return dictfetchone(cursor)


def scalar(sql, params=None):
    """Run a SELECT of a single column/row and return that one value."""
    with connection.cursor() as cursor:
        cursor.execute(sql, params or [])
        row = cursor.fetchone()
        return row[0] if row else None


def execute(sql, params=None):
    """Run an INSERT/UPDATE/DELETE, return the affected row count."""
    with connection.cursor() as cursor:
        cursor.execute(sql, params or [])
        return cursor.rowcount
