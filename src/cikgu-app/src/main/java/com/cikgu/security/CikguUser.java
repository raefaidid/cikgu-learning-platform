package com.cikgu.security;

import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

/**
 * UserDetails carrying the app_user surrogate key and display name so
 * controllers can scope queries to the logged-in user.
 */
public class CikguUser extends User {

    private final long userId;
    private final String fullName;
    private final String userType;

    public CikguUser(long userId, String fullName, String userType,
                     String email, String passwordHash,
                     Collection<? extends GrantedAuthority> authorities) {
        super(email, passwordHash, authorities);
        this.userId = userId;
        this.fullName = fullName;
        this.userType = userType;
    }

    public long getUserId() {
        return userId;
    }

    public String getFullName() {
        return fullName;
    }

    public String getUserType() {
        return userType;
    }
}
