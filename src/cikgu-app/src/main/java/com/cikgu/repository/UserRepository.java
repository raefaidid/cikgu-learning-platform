package com.cikgu.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.cikgu.model.TutorNode;
import com.cikgu.model.UserProfile;

@Repository
public class UserRepository {

    private final JdbcTemplate jdbc;

    public UserRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Sequence-based PK: the application draws the id, the trigger is the fallback. */
    public long nextUserId() {
        return jdbc.queryForObject("SELECT cikgu_user_seq.NEXTVAL FROM dual", Long.class);
    }

    public boolean emailExists(String email) {
        Integer n = jdbc.queryForObject(
                "SELECT COUNT(*) FROM app_user WHERE LOWER(email) = LOWER(?)", Integer.class, email);
        return n != null && n > 0;
    }

    public void insertAppUser(long userId, String fullName, String email,
                              String passwordHash, String phone, String userType) {
        jdbc.update("""
                INSERT INTO app_user (user_id, full_name, email, password_hash, phone, user_type)
                VALUES (?, ?, ?, ?, ?, ?)
                """, userId, fullName, email, passwordHash, phone, userType);
    }

    public void insertLearner(long userId, String educationBackground, String parsedSkills) {
        jdbc.update("""
                INSERT INTO learner (user_id, education_background, parsed_skills)
                VALUES (?, ?, ?)
                """, userId, educationBackground, parsedSkills);
    }

    public void insertTutor(long userId, String expertise, Integer yearsExperience) {
        jdbc.update("""
                INSERT INTO tutor (user_id, mentor_id, expertise, years_experience)
                VALUES (?, NULL, ?, ?)
                """, userId, expertise, yearsExperience);
    }

    private static final RowMapper<UserProfile> PROFILE_MAPPER = (rs, i) -> new UserProfile(
            rs.getLong("user_id"),
            rs.getString("full_name"),
            rs.getString("email"),
            rs.getString("phone"),
            rs.getDate("date_joined") == null ? null : rs.getDate("date_joined").toLocalDate(),
            rs.getString("user_type"),
            rs.getString("education_background"),
            rs.getString("parsed_skills"),
            rs.getString("expertise"),
            rs.getObject("years_experience") == null ? null : rs.getInt("years_experience"),
            rs.getObject("mentor_id") == null ? null : rs.getLong("mentor_id"),
            rs.getString("mentor_name"));

    /** Inheritance demo: superclass row outer-joined with both subclass tables. */
    public Optional<UserProfile> findProfile(long userId) {
        List<UserProfile> found = jdbc.query("""
                SELECT au.user_id, au.full_name, au.email, au.phone, au.date_joined, au.user_type,
                       l.education_background, l.parsed_skills,
                       t.expertise, t.years_experience, t.mentor_id,
                       mau.full_name AS mentor_name
                  FROM app_user au
                  LEFT JOIN learner  l   ON l.user_id   = au.user_id
                  LEFT JOIN tutor    t   ON t.user_id   = au.user_id
                  LEFT JOIN app_user mau ON mau.user_id = t.mentor_id
                 WHERE au.user_id = ?
                """, PROFILE_MAPPER, userId);
        return found.stream().findFirst();
    }

    public void updateAppUser(long userId, String fullName, String phone) {
        jdbc.update("UPDATE app_user SET full_name = ?, phone = ? WHERE user_id = ?",
                fullName, phone, userId);
    }

    public void updateLearner(long userId, String educationBackground, String parsedSkills) {
        jdbc.update("UPDATE learner SET education_background = ?, parsed_skills = ? WHERE user_id = ?",
                educationBackground, parsedSkills, userId);
    }

    public void updateTutor(long userId, String expertise, Integer yearsExperience) {
        jdbc.update("UPDATE tutor SET expertise = ?, years_experience = ? WHERE user_id = ?",
                expertise, yearsExperience, userId);
    }

    // ------------------------------------------------------------------
    // Recursive relationship: tutor mentorship
    // ------------------------------------------------------------------

    private static final RowMapper<TutorNode> NODE_MAPPER = (rs, i) -> new TutorNode(
            rs.getLong("user_id"),
            rs.getString("full_name"),
            rs.getString("expertise"),
            rs.getObject("years_experience") == null ? null : rs.getInt("years_experience"),
            rs.getObject("mentor_id") == null ? null : rs.getLong("mentor_id"),
            rs.getString("mentor_name"),
            rs.getInt("tree_level"));

    /** Full mentorship hierarchy via Oracle CONNECT BY PRIOR. */
    public List<TutorNode> mentorshipHierarchy() {
        return jdbc.query("""
                SELECT t.user_id, au.full_name, t.expertise, t.years_experience,
                       t.mentor_id,
                       (SELECT m.full_name FROM app_user m WHERE m.user_id = t.mentor_id) AS mentor_name,
                       LEVEL AS tree_level
                  FROM tutor t
                  JOIN app_user au ON au.user_id = t.user_id
                 START WITH t.mentor_id IS NULL
                CONNECT BY PRIOR t.user_id = t.mentor_id
                 ORDER SIBLINGS BY au.full_name
                """, NODE_MAPPER);
    }

    /** Direct mentees of one tutor (for the tutor dashboard). */
    public List<TutorNode> directMentees(long mentorId) {
        return jdbc.query("""
                SELECT t.user_id, au.full_name, t.expertise, t.years_experience,
                       t.mentor_id,
                       (SELECT m.full_name FROM app_user m WHERE m.user_id = t.mentor_id) AS mentor_name,
                       1 AS tree_level
                  FROM tutor t
                  JOIN app_user au ON au.user_id = t.user_id
                 WHERE t.mentor_id = ?
                 ORDER BY au.full_name
                """, NODE_MAPPER, mentorId);
    }

    /**
     * Tutors this tutor may pick as mentor: everyone except the tutor's own
     * subtree (assigning a descendant as mentor would create a cycle).
     */
    public List<TutorNode> eligibleMentors(long tutorId) {
        return jdbc.query("""
                SELECT t.user_id, au.full_name, t.expertise, t.years_experience,
                       t.mentor_id,
                       (SELECT m.full_name FROM app_user m WHERE m.user_id = t.mentor_id) AS mentor_name,
                       1 AS tree_level
                  FROM tutor t
                  JOIN app_user au ON au.user_id = t.user_id
                 WHERE t.user_id NOT IN (
                          SELECT s.user_id
                            FROM tutor s
                           START WITH s.user_id = ?
                          CONNECT BY PRIOR s.user_id = s.mentor_id)
                 ORDER BY au.full_name
                """, NODE_MAPPER, tutorId);
    }

    public void updateMentor(long tutorId, Long mentorId) {
        jdbc.update("UPDATE tutor SET mentor_id = ? WHERE user_id = ?", mentorId, tutorId);
    }
}
