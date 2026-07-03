package com.cikgu.service;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

import javax.sql.DataSource;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class QueryConsoleService {

    public record QueryResult(List<String> columns, List<List<Object>> rows, int rowCount) {
    }

    private static final int MAX_ROWS = 200;

    /**
     * Statements the console refuses even inside a SELECT-looking input.
     * This is a guard against accidental DML from the demo console, not a
     * defense against a malicious DBA.
     */
    private static final Pattern FORBIDDEN = Pattern.compile(
            "\\b(insert|update|delete|merge|drop|alter|create|truncate|grant|revoke|call|begin|declare|commit|rollback|lock)\\b",
            Pattern.CASE_INSENSITIVE);

    private final JdbcTemplate jdbc;

    public QueryConsoleService(DataSource dataSource) {
        this.jdbc = new JdbcTemplate(dataSource);
        this.jdbc.setMaxRows(MAX_ROWS);
    }

    public QueryResult run(String sql) {
        String statement = sql == null ? "" : sql.trim();
        if (statement.endsWith(";")) {
            statement = statement.substring(0, statement.length() - 1).trim();
        }
        if (statement.isEmpty()) {
            throw new IllegalArgumentException("Enter a SELECT statement.");
        }
        if (statement.contains(";")) {
            throw new IllegalArgumentException("Only a single statement is allowed.");
        }
        String lower = statement.toLowerCase();
        if (!lower.startsWith("select") && !lower.startsWith("with")) {
            throw new IllegalArgumentException("Only SELECT statements are allowed in this console.");
        }
        if (FORBIDDEN.matcher(statement).find()) {
            throw new IllegalArgumentException("Only read-only SELECT statements are allowed in this console.");
        }

        return jdbc.query(statement, rs -> {
            var meta = rs.getMetaData();
            int cols = meta.getColumnCount();
            List<String> columns = new ArrayList<>();
            for (int c = 1; c <= cols; c++) {
                columns.add(meta.getColumnLabel(c));
            }
            List<List<Object>> rows = new ArrayList<>();
            while (rs.next()) {
                List<Object> row = new ArrayList<>();
                for (int c = 1; c <= cols; c++) {
                    row.add(rs.getObject(c));
                }
                rows.add(row);
            }
            return new QueryResult(columns, rows, rows.size());
        });
    }
}
