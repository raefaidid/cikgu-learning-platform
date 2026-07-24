"""GOAL table access — port of GoalRepository.java."""

from .. import db


def find_by_learner(user_id):
    return db.query_all(
        """
        SELECT goal_id, user_id, goal_title, target_outcome, target_date
          FROM goal
         WHERE user_id = %s
         ORDER BY target_date NULLS LAST, goal_id
        """,
        [user_id],
    )


def find_by_id(goal_id):
    return db.query_one(
        """
        SELECT goal_id, user_id, goal_title, target_outcome, target_date
          FROM goal
         WHERE goal_id = %s
        """,
        [goal_id],
    )


def insert(user_id, title, outcome, target_date):
    db.execute(
        """
        INSERT INTO goal (user_id, goal_title, target_outcome, target_date)
        VALUES (%s, %s, %s, %s)
        """,
        [user_id, title, outcome, db.to_oracle_date(target_date)],
    )


def update(goal_id, owner_id, title, outcome, target_date):
    db.execute(
        """
        UPDATE goal
           SET goal_title = %s, target_outcome = %s, target_date = %s
         WHERE goal_id = %s AND user_id = %s
        """,
        [title, outcome, db.to_oracle_date(target_date), goal_id, owner_id],
    )


def delete(goal_id, owner_id):
    db.execute("DELETE FROM goal WHERE goal_id = %s AND user_id = %s", [goal_id, owner_id])
