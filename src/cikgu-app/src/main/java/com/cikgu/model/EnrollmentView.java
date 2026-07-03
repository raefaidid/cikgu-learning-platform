package com.cikgu.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** An ENROLLMENT bridge row joined with learner, module and goal data. */
public record EnrollmentView(
        long userId,
        String learnerName,
        long moduleId,
        String moduleTitle,
        Long goalId,
        String goalTitle,
        LocalDate targetDate,
        LocalDate enrollDate,
        double progressScore,
        String status,
        LocalDateTime lastUpdatedAt,
        boolean behindSchedule) {
}
