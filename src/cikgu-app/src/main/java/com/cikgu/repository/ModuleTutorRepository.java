package com.cikgu.repository;

import java.util.List;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.cikgu.model.ModuleTeacher;
import com.cikgu.model.TutorNode;

@Repository
public class ModuleTutorRepository {

    private final JdbcTemplate jdbc;

    public ModuleTutorRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static final RowMapper<ModuleTeacher> MAPPER = (rs, i) -> new ModuleTeacher(
            rs.getLong("module_id"),
            rs.getLong("user_id"),
            rs.getString("tutor_name"),
            rs.getString("expertise"),
            rs.getString("teaching_role"),
            rs.getDate("assigned_date") == null ? null : rs.getDate("assigned_date").toLocalDate());

    public List<ModuleTeacher> findByModule(long moduleId) {
        return jdbc.query("""
                SELECT mt.module_id, mt.user_id, au.full_name AS tutor_name,
                       t.expertise, mt.teaching_role, mt.assigned_date
                  FROM module_tutor mt
                  JOIN tutor    t  ON t.user_id  = mt.user_id
                  JOIN app_user au ON au.user_id = mt.user_id
                 WHERE mt.module_id = ?
                 ORDER BY CASE mt.teaching_role WHEN 'LEAD' THEN 0 ELSE 1 END, au.full_name
                """, MAPPER, moduleId);
    }

    public void assign(long moduleId, long tutorId, String teachingRole) {
        jdbc.update("""
                INSERT INTO module_tutor (module_id, user_id, teaching_role)
                VALUES (?, ?, ?)
                """, moduleId, tutorId, teachingRole);
    }

    /** Only CO_TEACHER rows may be removed; the LEAD row stays with the module. */
    public int removeCoTeacher(long moduleId, long tutorId) {
        return jdbc.update("""
                DELETE FROM module_tutor
                 WHERE module_id = ? AND user_id = ? AND teaching_role = 'CO_TEACHER'
                """, moduleId, tutorId);
    }

    public boolean teaches(long tutorId, long moduleId) {
        Integer n = jdbc.queryForObject("""
                SELECT COUNT(*) FROM module_tutor WHERE module_id = ? AND user_id = ?
                """, Integer.class, moduleId, tutorId);
        return n != null && n > 0;
    }

    /** Tutors not yet assigned to the module (dropdown for adding a co-teacher). */
    public List<TutorNode> tutorsNotOnModule(long moduleId) {
        return jdbc.query("""
                SELECT t.user_id, au.full_name, t.expertise, t.years_experience,
                       t.mentor_id, NULL AS mentor_name, 1 AS tree_level
                  FROM tutor t
                  JOIN app_user au ON au.user_id = t.user_id
                 WHERE NOT EXISTS (SELECT 1 FROM module_tutor mt
                                    WHERE mt.module_id = ? AND mt.user_id = t.user_id)
                 ORDER BY au.full_name
                """,
                (rs, i) -> new TutorNode(
                        rs.getLong("user_id"),
                        rs.getString("full_name"),
                        rs.getString("expertise"),
                        rs.getObject("years_experience") == null ? null : rs.getInt("years_experience"),
                        rs.getObject("mentor_id") == null ? null : rs.getLong("mentor_id"),
                        rs.getString("mentor_name"),
                        rs.getInt("tree_level")),
                moduleId);
    }
}
