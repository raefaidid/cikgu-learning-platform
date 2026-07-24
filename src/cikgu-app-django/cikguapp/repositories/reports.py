"""Reporting queries — port of ReportRepository.java."""

from .. import db


def top_modules():
    """Top-performing modules: average progress score per module, ranked."""
    return db.query_all(
        """
        SELECT m.module_title              AS module_title,
               COUNT(e.user_id)             AS enrolled_learners,
               ROUND(AVG(e.progress_score), 1) AS avg_progress
          FROM module m
          JOIN enrollment e ON e.module_id = m.module_id
         GROUP BY m.module_title
         ORDER BY AVG(e.progress_score) DESC
        """
    )


def behind_schedule():
    """
    Learners behind schedule: the linked goal's target_date has passed but
    the enrollment is not COMPLETED (flag computed in module_progress_v).
    """
    rows = db.query_all(
        """
        SELECT v.user_id, v.learner_name, v.module_id, v.module_title,
               v.goal_id, v.goal_title, v.target_date, v.enroll_date,
               v.progress_score, v.status, v.last_updated_at, v.behind_schedule
          FROM module_progress_v v
         WHERE v.behind_schedule = 'Y'
         ORDER BY v.target_date, v.learner_name
        """
    )
    for row in rows:
        row["behind_schedule"] = True
    return rows
