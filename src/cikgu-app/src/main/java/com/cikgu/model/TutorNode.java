package com.cikgu.model;

/** One row of the CONNECT BY PRIOR mentorship hierarchy query. */
public record TutorNode(
        long userId,
        String fullName,
        String expertise,
        Integer yearsExperience,
        Long mentorId,
        String mentorName,
        int level) {
}
