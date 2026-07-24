"""MODULE table access — port of ModuleRepository.java."""

from .. import db

_BASE_SELECT = """
    SELECT m.module_id, m.module_title, m.description, m.duration_hours, m.difficulty,
           (SELECT au.full_name
              FROM module_tutor mt
              JOIN app_user au ON au.user_id = mt.user_id
             WHERE mt.module_id = m.module_id
               AND mt.teaching_role = 'LEAD') AS lead_tutor_name
      FROM module m
"""


def search(q, difficulty):
    """Module browser: optional title search and difficulty filter."""
    sql = [_BASE_SELECT, " WHERE 1 = 1"]
    params = []
    if q:
        q = q.strip()
    if q:
        sql.append(" AND LOWER(m.module_title) LIKE %s")
        params.append(f"%{q.lower()}%")
    if difficulty:
        sql.append(" AND m.difficulty = %s")
        params.append(difficulty)
    sql.append(" ORDER BY m.module_title")
    return db.query_all("".join(sql), params)


def find_by_id(module_id):
    return db.query_one(_BASE_SELECT + " WHERE m.module_id = %s", [module_id])


def find_by_tutor(tutor_id):
    """Modules a tutor leads or co-teaches."""
    return db.query_all(
        _BASE_SELECT
        + """
         WHERE EXISTS (SELECT 1 FROM module_tutor mt
                        WHERE mt.module_id = m.module_id AND mt.user_id = %s)
         ORDER BY m.module_title
        """,
        [tutor_id],
    )


def next_module_id():
    """Sequence-based PK: the application draws the id, the trigger is the fallback."""
    return db.scalar("SELECT cikgu_module_seq.NEXTVAL FROM dual")


def insert(module_id, title, description, duration_hours, difficulty):
    db.execute(
        """
        INSERT INTO module (module_id, module_title, description, duration_hours, difficulty)
        VALUES (%s, %s, %s, %s, %s)
        """,
        [module_id, title, description, duration_hours, difficulty],
    )


def update(module_id, title, description, duration_hours, difficulty):
    db.execute(
        """
        UPDATE module
           SET module_title = %s, description = %s, duration_hours = %s, difficulty = %s
         WHERE module_id = %s
        """,
        [title, description, duration_hours, difficulty, module_id],
    )


def delete(module_id):
    """Cascading FKs remove module_tutor and enrollment child rows."""
    db.execute("DELETE FROM module WHERE module_id = %s", [module_id])
