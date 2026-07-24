"""Ad hoc read-only SQL console — port of QueryConsoleService.java."""

import re
from dataclasses import dataclass

from django.db import connection

MAX_ROWS = 200

# Statements the console refuses even inside a SELECT-looking input. This is
# a guard against accidental DML from the demo console, not a defense
# against a malicious DBA.
FORBIDDEN = re.compile(
    r"\b(insert|update|delete|merge|drop|alter|create|truncate|grant|revoke"
    r"|call|begin|declare|commit|rollback|lock)\b",
    re.IGNORECASE,
)


class ConsoleError(Exception):
    """Raised for input the console rejects before ever reaching Oracle."""


@dataclass
class QueryResult:
    columns: list
    rows: list
    row_count: int


def run(sql):
    statement = (sql or "").strip()
    if statement.endswith(";"):
        statement = statement[:-1].strip()
    if not statement:
        raise ConsoleError("Enter a SELECT statement.")
    if ";" in statement:
        raise ConsoleError("Only a single statement is allowed.")

    lower = statement.lower()
    if not (lower.startswith("select") or lower.startswith("with")):
        raise ConsoleError("Only SELECT statements are allowed in this console.")
    if FORBIDDEN.search(statement):
        raise ConsoleError("Only read-only SELECT statements are allowed in this console.")

    with connection.cursor() as cursor:
        cursor.execute(statement)
        columns = [col[0] for col in cursor.description]
        rows = [list(row) for row in cursor.fetchmany(MAX_ROWS)]
        return QueryResult(columns=columns, rows=rows, row_count=len(rows))
