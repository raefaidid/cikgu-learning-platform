package com.cikgu.model;

import java.time.LocalDate;

public record Goal(
        long goalId,
        long userId,
        String goalTitle,
        String targetOutcome,
        LocalDate targetDate) {
}
