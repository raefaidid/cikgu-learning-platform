package com.cikgu.controller;

import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.cikgu.service.QueryConsoleService;

/** Ad hoc read-only SQL console, available to both roles. */
@Controller
public class ConsoleController {

    private final QueryConsoleService console;

    public ConsoleController(QueryConsoleService console) {
        this.console = console;
    }

    @GetMapping("/console")
    public String console(Model model) {
        model.addAttribute("sql", "SELECT module_title, difficulty, duration_hours FROM module ORDER BY module_title");
        return "console";
    }

    @PostMapping("/console")
    public String run(@RequestParam String sql, Model model) {
        model.addAttribute("sql", sql);
        try {
            model.addAttribute("result", console.run(sql));
        } catch (IllegalArgumentException e) {
            model.addAttribute("consoleError", e.getMessage());
        } catch (DataAccessException e) {
            String root = e.getMostSpecificCause() == null
                    ? e.getMessage() : e.getMostSpecificCause().getMessage();
            model.addAttribute("consoleError", "Oracle error: " + root);
        }
        return "console";
    }
}
