package com.cikgu.model;

/** A row of the MODULE table, with the LEAD tutor's name joined in for lists. */
public record LearningModule(
        long moduleId,
        String moduleTitle,
        String description,
        Integer durationHours,
        String difficulty,
        String leadTutorName) {
}
