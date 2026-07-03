package com.cikgu.repository;

import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import com.cikgu.model.EnrollmentView;

@Repository
public class ReportRepository {

    private final JdbcTemplate jdbc;

    public ReportRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Top-performing modules: average progress score per module, ranked. */
    public List<Map<String, Object>> topModules() {
        return jdbc.queryForList("""
                SELECT m.module_title            AS "moduleTitle",
                       COUNT(e.user_id)          AS "enrolledLearners",
                       ROUND(AVG(e.progress_score), 1) AS "avgProgress"
                  FROM module m
                  JOIN enrollment e ON e.module_id = m.module_id
                 GROUP BY m.module_title
                 ORDER BY AVG(e.progress_score) DESC
                """);
    }

    /**
     * Learners behind schedule: the linked goal's target_date has passed
     * but the enrollment is not COMPLETED (flag computed in the view).
     */
    public List<EnrollmentView> behindSchedule() {
        return jdbc.query("""
                SELECT v.user_id, v.learner_name, v.module_id, v.module_title,
                       v.goal_id, v.goal_title, v.target_date, v.enroll_date,
                       v.progress_score, v.status, v.last_updated_at, v.behind_schedule
                  FROM module_progress_v v
                 WHERE v.behind_schedule = 'Y'
                 ORDER BY v.target_date, v.learner_name
                """, (rs, i) -> new EnrollmentView(
                        rs.getLong("user_id"),
                        rs.getString("learner_name"),
                        rs.getLong("module_id"),
                        rs.getString("module_title"),
                        rs.getObject("goal_id") == null ? null : rs.getLong("goal_id"),
                        rs.getString("goal_title"),
                        rs.getDate("target_date") == null ? null : rs.getDate("target_date").toLocalDate(),
                        rs.getDate("enroll_date") == null ? null : rs.getDate("enroll_date").toLocalDate(),
                        rs.getDouble("progress_score"),
                        rs.getString("status"),
                        rs.getTimestamp("last_updated_at") == null ? null
                                : rs.getTimestamp("last_updated_at").toLocalDateTime(),
                        true));
    }
}
