package com.cikgu.security;

import java.util.List;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CikguUserDetailsService implements UserDetailsService {

    private final JdbcTemplate jdbc;

    public CikguUserDetailsService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        List<UserDetails> found = jdbc.query("""
                SELECT user_id, full_name, email, password_hash, user_type
                  FROM app_user
                 WHERE LOWER(email) = LOWER(?)
                """,
                (rs, i) -> new CikguUser(
                        rs.getLong("user_id"),
                        rs.getString("full_name"),
                        rs.getString("user_type"),
                        rs.getString("email"),
                        rs.getString("password_hash"),
                        List.of(new SimpleGrantedAuthority("ROLE_" + rs.getString("user_type")))),
                email);
        if (found.isEmpty()) {
            throw new UsernameNotFoundException("No account for " + email);
        }
        return found.get(0);
    }
}
