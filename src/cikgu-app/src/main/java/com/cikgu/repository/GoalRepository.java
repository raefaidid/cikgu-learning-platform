package com.cikgu.repository;

import java.sql.Date;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.cikgu.model.Goal;

@Repository
public class GoalRepository {

    private final JdbcTemplate jdbc;

    public GoalRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static final RowMapper<Goal> MAPPER = (rs, i) -> new Goal(
            rs.getLong("goal_id"),
            rs.getLong("user_id"),
            rs.getString("goal_title"),
            rs.getString("target_outcome"),
            rs.getDate("target_date") == null ? null : rs.getDate("target_date").toLocalDate());

    public List<Goal> findByLearner(long userId) {
        return jdbc.query("""
                SELECT goal_id, user_id, goal_title, target_outcome, target_date
                  FROM goal
                 WHERE user_id = ?
                 ORDER BY target_date NULLS LAST, goal_id
                """, MAPPER, userId);
    }

    public Optional<Goal> findById(long goalId) {
        return jdbc.query("""
                SELECT goal_id, user_id, goal_title, target_outcome, target_date
                  FROM goal
                 WHERE goal_id = ?
                """, MAPPER, goalId).stream().findFirst();
    }

    public void insert(long userId, String title, String outcome, LocalDate targetDate) {
        jdbc.update("""
                INSERT INTO goal (user_id, goal_title, target_outcome, target_date)
                VALUES (?, ?, ?, ?)
                """, userId, title, outcome,
                targetDate == null ? null : Date.valueOf(targetDate));
    }

    public void update(long goalId, long ownerId, String title, String outcome, LocalDate targetDate) {
        jdbc.update("""
                UPDATE goal
                   SET goal_title = ?, target_outcome = ?, target_date = ?
                 WHERE goal_id = ? AND user_id = ?
                """, title, outcome,
                targetDate == null ? null : Date.valueOf(targetDate), goalId, ownerId);
    }

    public void delete(long goalId, long ownerId) {
        jdbc.update("DELETE FROM goal WHERE goal_id = ? AND user_id = ?", goalId, ownerId);
    }
}
