package com.cikgu.model;

import java.time.LocalDate;

/**
 * APP_USER joined with its subclass row (LEARNER or TUTOR) — the
 * inheritance demo: one profile built from superclass + subclass tables.
 */
public record UserProfile(
        long userId,
        String fullName,
        String email,
        String phone,
        LocalDate dateJoined,
        String userType,
        // learner fields (null for tutors)
        String educationBackground,
        String parsedSkills,
        // tutor fields (null for learners)
        String expertise,
        Integer yearsExperience,
        Long mentorId,
        String mentorName) {
}
