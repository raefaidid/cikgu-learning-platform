package com.cikgu.controller;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.cikgu.repository.ReportRepository;

/** Reporting dashboard, available to both roles. */
@Controller
public class ReportController {

    private final ReportRepository reports;

    public ReportController(ReportRepository reports) {
        this.reports = reports;
    }

    @GetMapping("/reports")
    public String reports(Model model) {
        List<Map<String, Object>> topModules = reports.topModules();
        model.addAttribute("topModules", topModules);
        model.addAttribute("chartLabels",
                topModules.stream().map(m -> (Object) m.get("moduleTitle")).toList());
        model.addAttribute("chartValues",
                topModules.stream().map(m -> (Object) m.get("avgProgress")).toList());
        model.addAttribute("behindSchedule", reports.behindSchedule());
        return "reports";
    }
}
