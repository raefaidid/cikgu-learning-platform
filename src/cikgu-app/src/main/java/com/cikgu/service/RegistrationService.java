package com.cikgu.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cikgu.repository.UserRepository;

@Service
public class RegistrationService {

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;

    public RegistrationService(UserRepository users, PasswordEncoder passwordEncoder) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Transaction-management demo (graded): the APP_USER superclass row and
     * the matching subclass row (LEARNER or TUTOR) are inserted in ONE
     * transaction — if either insert fails, both roll back and no orphan
     * superclass row is left behind.
     */
    @Transactional
    public long register(String fullName, String email, String rawPassword, String phone,
                         String userType,
                         String educationBackground, String parsedSkills,
                         String expertise, Integer yearsExperience) {
        if (users.emailExists(email)) {
            throw new IllegalArgumentException("An account with that email already exists.");
        }
        if (!"LEARNER".equals(userType) && !"TUTOR".equals(userType)) {
            throw new IllegalArgumentException("Account type must be LEARNER or TUTOR.");
        }

        long userId = users.nextUserId();
        users.insertAppUser(userId, fullName, email,
                passwordEncoder.encode(rawPassword), phone, userType);

        if ("LEARNER".equals(userType)) {
            users.insertLearner(userId, educationBackground, parsedSkills);
        } else {
            users.insertTutor(userId, expertise, yearsExperience);
        }
        return userId;
    }
}
