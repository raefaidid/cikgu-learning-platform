package com.cikgu.repository;

import java.util.List;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.cikgu.model.EnrollmentView;

@Repository
public class EnrollmentRepository {

    private final JdbcTemplate jdbc;

    public EnrollmentRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** All reads go through the MODULE_PROGRESS_V reporting view. */
    private static final String BASE_SELECT = """
            SELECT v.user_id, v.learner_name, v.module_id, v.module_title,
                   v.goal_id, v.goal_title, v.target_date, v.enroll_date,
                   v.progress_score, v.status, v.last_updated_at, v.behind_schedule
              FROM module_progress_v v
            """;

    private static final RowMapper<EnrollmentView> MAPPER = (rs, i) -> new EnrollmentView(
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
            "Y".equals(rs.getString("behind_schedule")));

    public List<EnrollmentView> findByLearner(long userId) {
        return jdbc.query(BASE_SELECT + " WHERE v.user_id = ? ORDER BY v.enroll_date DESC",
                MAPPER, userId);
    }

    public List<EnrollmentView> findByModule(long moduleId) {
        return jdbc.query(BASE_SELECT + " WHERE v.module_id = ? ORDER BY v.learner_name",
                MAPPER, moduleId);
    }

    /** Enrollments in every module the given tutor leads or co-teaches. */
    public List<EnrollmentView> findByTutor(long tutorId) {
        return jdbc.query(BASE_SELECT + """
                 WHERE v.module_id IN (SELECT mt.module_id FROM module_tutor mt WHERE mt.user_id = ?)
                 ORDER BY v.module_title, v.learner_name
                """, MAPPER, tutorId);
    }

    public boolean exists(long userId, long moduleId) {
        Integer n = jdbc.queryForObject(
                "SELECT COUNT(*) FROM enrollment WHERE user_id = ? AND module_id = ?",
                Integer.class, userId, moduleId);
        return n != null && n > 0;
    }

    public void enroll(long userId, long moduleId, Long goalId) {
        jdbc.update("""
                INSERT INTO enrollment (user_id, module_id, goal_id)
                VALUES (?, ?, ?)
                """, userId, moduleId, goalId);
    }

    /** Fires the BEFORE UPDATE trigger that maintains last_updated_at. */
    public void updateProgress(long userId, long moduleId, double progressScore, String status) {
        jdbc.update("""
                UPDATE enrollment
                   SET progress_score = ?, status = ?
                 WHERE user_id = ? AND module_id = ?
                """, progressScore, status, userId, moduleId);
    }

    public void delete(long userId, long moduleId) {
        jdbc.update("DELETE FROM enrollment WHERE user_id = ? AND module_id = ?",
                userId, moduleId);
    }
}
