package com.cikgu.model;

import java.time.LocalDate;

/** A MODULE_TUTOR bridge row joined with the tutor's profile. */
public record ModuleTeacher(
        long moduleId,
        long userId,
        String tutorName,
        String expertise,
        String teachingRole,
        LocalDate assignedDate) {
}
