"""
Schema introspection for the SQL console's table/column reference panel.
Reads Oracle's own data dictionary (USER_TAB_COLUMNS / USER_OBJECTS) rather
than hard-coding the CIKGU table list, so the reference never drifts out of
sync with schema/cikgu/cikgu_create.sql.
"""

from .. import db

_COLUMNS_SQL = """
    SELECT c.table_name,
           o.object_type,
           c.column_name,
           c.data_type
             || CASE
                  WHEN c.data_type IN ('VARCHAR2', 'CHAR', 'NVARCHAR2') THEN '(' || c.data_length || ')'
                  WHEN c.data_type = 'NUMBER' AND c.data_precision IS NOT NULL THEN
                    '(' || c.data_precision || CASE WHEN c.data_scale > 0 THEN ',' || c.data_scale ELSE '' END || ')'
                  ELSE ''
                END AS data_type_display,
           c.nullable,
           c.column_id
      FROM user_tab_columns c
      JOIN user_objects o ON o.object_name = c.table_name AND o.object_type IN ('TABLE', 'VIEW')
     ORDER BY o.object_type, c.table_name, c.column_id
"""


def list_tables_and_columns():
    """
    Every table/view in the CIKGU schema with its columns, grouped and in
    column-definition order, e.g.:
        [{"table_name": "APP_USER", "object_type": "TABLE",
          "columns": [{"column_name": "USER_ID", "data_type_display": "NUMBER", "not_null": True}, ...]}, ...]
    """
    rows = db.query_all(_COLUMNS_SQL)
    tables = []
    current = None
    for row in rows:
        if current is None or current["table_name"] != row["table_name"]:
            current = {
                "table_name": row["table_name"],
                "object_type": row["object_type"],
                "columns": [],
            }
            tables.append(current)
        current["columns"].append({
            "column_name": row["column_name"],
            "data_type_display": row["data_type_display"],
            "not_null": row["nullable"] == "N",
        })
    return tables
