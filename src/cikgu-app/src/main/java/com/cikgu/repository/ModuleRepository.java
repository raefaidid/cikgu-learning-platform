package com.cikgu.repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.cikgu.model.LearningModule;

@Repository
public class ModuleRepository {

    private final JdbcTemplate jdbc;

    public ModuleRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static final String BASE_SELECT = """
            SELECT m.module_id, m.module_title, m.description, m.duration_hours, m.difficulty,
                   (SELECT au.full_name
                      FROM module_tutor mt
                      JOIN app_user au ON au.user_id = mt.user_id
                     WHERE mt.module_id = m.module_id
                       AND mt.teaching_role = 'LEAD') AS lead_tutor_name
              FROM module m
            """;

    private static final RowMapper<LearningModule> MAPPER = (rs, i) -> new LearningModule(
            rs.getLong("module_id"),
            rs.getString("module_title"),
            rs.getString("description"),
            rs.getObject("duration_hours") == null ? null : rs.getInt("duration_hours"),
            rs.getString("difficulty"),
            rs.getString("lead_tutor_name"));

    /** Module browser: optional title search and difficulty filter. */
    public List<LearningModule> search(String q, String difficulty) {
        StringBuilder sql = new StringBuilder(BASE_SELECT).append(" WHERE 1 = 1");
        List<Object> args = new ArrayList<>();
        if (q != null && !q.isBlank()) {
            sql.append(" AND LOWER(m.module_title) LIKE ?");
            args.add("%" + q.trim().toLowerCase() + "%");
        }
        if (difficulty != null && !difficulty.isBlank()) {
            sql.append(" AND m.difficulty = ?");
            args.add(difficulty);
        }
        sql.append(" ORDER BY m.module_title");
        return jdbc.query(sql.toString(), MAPPER, args.toArray());
    }

    public Optional<LearningModule> findById(long moduleId) {
        return jdbc.query(BASE_SELECT + " WHERE m.module_id = ?", MAPPER, moduleId)
                .stream().findFirst();
    }

    /** Modules a tutor leads or co-teaches. */
    public List<LearningModule> findByTutor(long tutorId) {
        return jdbc.query(BASE_SELECT + """
                 WHERE EXISTS (SELECT 1 FROM module_tutor mt
                                WHERE mt.module_id = m.module_id AND mt.user_id = ?)
                 ORDER BY m.module_title
                """, MAPPER, tutorId);
    }

    /** Sequence-based PK: the application draws the id, the trigger is the fallback. */
    public long nextModuleId() {
        return jdbc.queryForObject("SELECT cikgu_module_seq.NEXTVAL FROM dual", Long.class);
    }

    public void insert(long moduleId, String title, String description,
                       Integer durationHours, String difficulty) {
        jdbc.update("""
                INSERT INTO module (module_id, module_title, description, duration_hours, difficulty)
                VALUES (?, ?, ?, ?, ?)
                """, moduleId, title, description, durationHours, difficulty);
    }

    public void update(long moduleId, String title, String description,
                       Integer durationHours, String difficulty) {
        jdbc.update("""
                UPDATE module
                   SET module_title = ?, description = ?, duration_hours = ?, difficulty = ?
                 WHERE module_id = ?
                """, title, description, durationHours, difficulty, moduleId);
    }

    /** Cascading FKs remove module_tutor and enrollment child rows. */
    public void delete(long moduleId) {
        jdbc.update("DELETE FROM module WHERE module_id = ?", moduleId);
    }
}
