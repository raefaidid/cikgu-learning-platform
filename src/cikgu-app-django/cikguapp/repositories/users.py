"""app_user / learner / tutor access — registration, profile, mentorship.

Port of UserRepository.java. find_profile() is the inheritance demo: the
app_user superclass row outer-joined with both subclass tables. The
mentorship queries are the recursive-relationship demo (Oracle
CONNECT BY PRIOR on tutor.mentor_id -> tutor.user_id).
"""

from .. import db


def next_user_id():
    return db.scalar("SELECT cikgu_user_seq.NEXTVAL FROM dual")


def email_exists(email):
    return db.scalar(
        "SELECT COUNT(*) FROM app_user WHERE LOWER(email) = LOWER(%s)", [email]
    ) > 0


def insert_app_user(user_id, full_name, email, password_hash, phone, user_type):
    db.execute(
        """
        INSERT INTO app_user (user_id, full_name, email, password_hash, phone, user_type)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        [user_id, full_name, email, password_hash, phone, user_type],
    )


def insert_learner(user_id, education_background, parsed_skills):
    db.execute(
        """
        INSERT INTO learner (user_id, education_background, parsed_skills)
        VALUES (%s, %s, %s)
        """,
        [user_id, education_background, parsed_skills],
    )


def insert_tutor(user_id, expertise, years_experience):
    db.execute(
        """
        INSERT INTO tutor (user_id, mentor_id, expertise, years_experience)
        VALUES (%s, NULL, %s, %s)
        """,
        [user_id, expertise, years_experience],
    )


def find_profile(user_id):
    """Inheritance demo: app_user LEFT JOIN learner LEFT JOIN tutor (+ mentor name)."""
    return db.query_one(
        """
        SELECT au.user_id, au.full_name, au.email, au.phone, au.date_joined, au.user_type,
               l.education_background, l.parsed_skills,
               t.expertise, t.years_experience, t.mentor_id,
               mau.full_name AS mentor_name
          FROM app_user au
          LEFT JOIN learner  l   ON l.user_id   = au.user_id
          LEFT JOIN tutor    t   ON t.user_id   = au.user_id
          LEFT JOIN app_user mau ON mau.user_id = t.mentor_id
         WHERE au.user_id = %s
        """,
        [user_id],
    )


def update_app_user(user_id, full_name, phone):
    db.execute(
        "UPDATE app_user SET full_name = %s, phone = %s WHERE user_id = %s",
        [full_name, phone, user_id],
    )


def update_learner(user_id, education_background, parsed_skills):
    db.execute(
        "UPDATE learner SET education_background = %s, parsed_skills = %s WHERE user_id = %s",
        [education_background, parsed_skills, user_id],
    )


def update_tutor(user_id, expertise, years_experience):
    db.execute(
        "UPDATE tutor SET expertise = %s, years_experience = %s WHERE user_id = %s",
        [expertise, years_experience, user_id],
    )


# --------------------------------------------------------------------
# Recursive relationship: tutor mentorship
# --------------------------------------------------------------------

_MENTORSHIP_HIERARCHY_SQL = """
    SELECT t.user_id, au.full_name, t.expertise, t.years_experience,
           t.mentor_id,
           (SELECT m.full_name FROM app_user m WHERE m.user_id = t.mentor_id) AS mentor_name,
           LEVEL AS tree_level
      FROM tutor t
      JOIN app_user au ON au.user_id = t.user_id
     START WITH t.mentor_id IS NULL
    CONNECT BY PRIOR t.user_id = t.mentor_id
     ORDER SIBLINGS BY au.full_name
"""


def mentorship_hierarchy():
    """Full mentorship tree via Oracle CONNECT BY PRIOR."""
    return db.query_all(_MENTORSHIP_HIERARCHY_SQL)


def direct_mentees(mentor_id):
    """Direct mentees of one tutor (for the tutor dashboard)."""
    return db.query_all(
        """
        SELECT t.user_id, au.full_name, t.expertise, t.years_experience,
               t.mentor_id,
               (SELECT m.full_name FROM app_user m WHERE m.user_id = t.mentor_id) AS mentor_name,
               1 AS tree_level
          FROM tutor t
          JOIN app_user au ON au.user_id = t.user_id
         WHERE t.mentor_id = %s
         ORDER BY au.full_name
        """,
        [mentor_id],
    )


def eligible_mentors(tutor_id):
    """
    Tutors this tutor may pick as mentor: everyone except the tutor's own
    subtree (assigning a descendant as mentor would create a cycle).
    """
    return db.query_all(
        """
        SELECT t.user_id, au.full_name, t.expertise, t.years_experience,
               t.mentor_id,
               (SELECT m.full_name FROM app_user m WHERE m.user_id = t.mentor_id) AS mentor_name,
               1 AS tree_level
          FROM tutor t
          JOIN app_user au ON au.user_id = t.user_id
         WHERE t.user_id NOT IN (
                  SELECT s.user_id
                    FROM tutor s
                   START WITH s.user_id = %s
                  CONNECT BY PRIOR s.user_id = s.mentor_id)
         ORDER BY au.full_name
        """,
        [tutor_id],
    )


def update_mentor(tutor_id, mentor_id):
    db.execute("UPDATE tutor SET mentor_id = %s WHERE user_id = %s", [mentor_id, tutor_id])
