"""MODULE_TUTOR bridge table access — port of ModuleTutorRepository.java.

Bridge entity #2: module <-> tutor, carrying teaching_role (LEAD/CO_TEACHER).
Exactly one LEAD per module is enforced in the database by the
modtut_one_lead_uix function-based unique index.
"""

from .. import db


def find_by_module(module_id):
    return db.query_all(
        """
        SELECT mt.module_id, mt.user_id, au.full_name AS tutor_name,
               t.expertise, mt.teaching_role, mt.assigned_date
          FROM module_tutor mt
          JOIN tutor    t  ON t.user_id  = mt.user_id
          JOIN app_user au ON au.user_id = mt.user_id
         WHERE mt.module_id = %s
         ORDER BY CASE mt.teaching_role WHEN 'LEAD' THEN 0 ELSE 1 END, au.full_name
        """,
        [module_id],
    )


def assign(module_id, tutor_id, teaching_role):
    db.execute(
        """
        INSERT INTO module_tutor (module_id, user_id, teaching_role)
        VALUES (%s, %s, %s)
        """,
        [module_id, tutor_id, teaching_role],
    )


def remove_co_teacher(module_id, tutor_id):
    """Only CO_TEACHER rows may be removed; the LEAD row stays with the module."""
    return db.execute(
        """
        DELETE FROM module_tutor
         WHERE module_id = %s AND user_id = %s AND teaching_role = 'CO_TEACHER'
        """,
        [module_id, tutor_id],
    )


def teaches(tutor_id, module_id):
    return db.scalar(
        "SELECT COUNT(*) FROM module_tutor WHERE module_id = %s AND user_id = %s",
        [module_id, tutor_id],
    ) > 0


def tutors_not_on_module(module_id):
    """Tutors not yet assigned to the module (dropdown for adding a co-teacher)."""
    return db.query_all(
        """
        SELECT t.user_id, au.full_name, t.expertise, t.years_experience,
               t.mentor_id, NULL AS mentor_name, 1 AS tree_level
          FROM tutor t
          JOIN app_user au ON au.user_id = t.user_id
         WHERE NOT EXISTS (SELECT 1 FROM module_tutor mt
                            WHERE mt.module_id = %s AND mt.user_id = t.user_id)
         ORDER BY au.full_name
        """,
        [module_id],
    )
