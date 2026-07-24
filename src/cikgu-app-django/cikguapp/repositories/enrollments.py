"""ENROLLMENT bridge table access — port of EnrollmentRepository.java.

Bridge entity #1: learner <-> module, carrying an optional goal_id. All
reads go through the module_progress_v reporting view (see
schema/cikgu/cikgu_create.sql), which also computes behind_schedule.
"""

from .. import db

_BASE_SELECT = """
    SELECT v.user_id, v.learner_name, v.module_id, v.module_title,
           v.goal_id, v.goal_title, v.target_date, v.enroll_date,
           v.progress_score, v.status, v.last_updated_at, v.behind_schedule
      FROM module_progress_v v
"""


def _with_behind_schedule_bool(rows):
    for row in rows:
        row["behind_schedule"] = row["behind_schedule"] == "Y"
    return rows


def find_by_learner(user_id):
    rows = db.query_all(_BASE_SELECT + " WHERE v.user_id = %s ORDER BY v.enroll_date DESC", [user_id])
    return _with_behind_schedule_bool(rows)


def find_by_module(module_id):
    rows = db.query_all(_BASE_SELECT + " WHERE v.module_id = %s ORDER BY v.learner_name", [module_id])
    return _with_behind_schedule_bool(rows)


def find_by_tutor(tutor_id):
    """Enrollments in every module the given tutor leads or co-teaches."""
    rows = db.query_all(
        _BASE_SELECT
        + """
         WHERE v.module_id IN (SELECT mt.module_id FROM module_tutor mt WHERE mt.user_id = %s)
         ORDER BY v.module_title, v.learner_name
        """,
        [tutor_id],
    )
    return _with_behind_schedule_bool(rows)


def exists(user_id, module_id):
    return db.scalar(
        "SELECT COUNT(*) FROM enrollment WHERE user_id = %s AND module_id = %s",
        [user_id, module_id],
    ) > 0


def enroll(user_id, module_id, goal_id):
    db.execute(
        """
        INSERT INTO enrollment (user_id, module_id, goal_id)
        VALUES (%s, %s, %s)
        """,
        [user_id, module_id, goal_id],
    )


def update_progress(user_id, module_id, progress_score, status):
    """Fires the BEFORE UPDATE trigger that maintains last_updated_at."""
    db.execute(
        """
        UPDATE enrollment
           SET progress_score = %s, status = %s
         WHERE user_id = %s AND module_id = %s
        """,
        [progress_score, status, user_id, module_id],
    )


def delete(user_id, module_id):
    db.execute("DELETE FROM enrollment WHERE user_id = %s AND module_id = %s", [user_id, module_id])
