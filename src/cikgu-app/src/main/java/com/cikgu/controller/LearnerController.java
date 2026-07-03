package com.cikgu.controller;

import java.time.LocalDate;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.cikgu.model.Goal;
import com.cikgu.repository.EnrollmentRepository;
import com.cikgu.repository.GoalRepository;
import com.cikgu.repository.ModuleRepository;
import com.cikgu.security.CikguUser;

@Controller
@RequestMapping("/learner")
public class LearnerController {

    private final GoalRepository goals;
    private final ModuleRepository modules;
    private final EnrollmentRepository enrollments;

    public LearnerController(GoalRepository goals, ModuleRepository modules,
                             EnrollmentRepository enrollments) {
        this.goals = goals;
        this.modules = modules;
        this.enrollments = enrollments;
    }

    @GetMapping("/dashboard")
    public String dashboard(@AuthenticationPrincipal CikguUser user, Model model) {
        model.addAttribute("goals", goals.findByLearner(user.getUserId()));
        model.addAttribute("enrollments", enrollments.findByLearner(user.getUserId()));
        return "learner/dashboard";
    }

    // ------------------------------------------------------------------
    // Goal management (create / edit / delete)
    // ------------------------------------------------------------------

    @GetMapping("/goals")
    public String goals(@AuthenticationPrincipal CikguUser user, Model model) {
        model.addAttribute("goals", goals.findByLearner(user.getUserId()));
        return "learner/goals";
    }

    @PostMapping("/goals")
    public String createGoal(@AuthenticationPrincipal CikguUser user,
                             @RequestParam String goalTitle,
                             @RequestParam(required = false) String targetOutcome,
                             @RequestParam(required = false)
                             @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate targetDate,
                             RedirectAttributes flash) {
        if (goalTitle.isBlank()) {
            flash.addFlashAttribute("err", "Goal title is required.");
            return "redirect:/learner/goals";
        }
        goals.insert(user.getUserId(), goalTitle.trim(), targetOutcome, targetDate);
        flash.addFlashAttribute("msg", "Goal created.");
        return "redirect:/learner/goals";
    }

    @GetMapping("/goals/{goalId}/edit")
    public String editGoalForm(@AuthenticationPrincipal CikguUser user,
                               @PathVariable long goalId, Model model,
                               RedirectAttributes flash) {
        Goal goal = goals.findById(goalId).orElse(null);
        if (goal == null || goal.userId() != user.getUserId()) {
            flash.addFlashAttribute("err", "Goal not found.");
            return "redirect:/learner/goals";
        }
        model.addAttribute("goal", goal);
        return "learner/goal-edit";
    }

    @PostMapping("/goals/{goalId}/edit")
    public String updateGoal(@AuthenticationPrincipal CikguUser user,
                             @PathVariable long goalId,
                             @RequestParam String goalTitle,
                             @RequestParam(required = false) String targetOutcome,
                             @RequestParam(required = false)
                             @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate targetDate,
                             RedirectAttributes flash) {
        goals.update(goalId, user.getUserId(), goalTitle.trim(), targetOutcome, targetDate);
        flash.addFlashAttribute("msg", "Goal updated.");
        return "redirect:/learner/goals";
    }

    @PostMapping("/goals/{goalId}/delete")
    public String deleteGoal(@AuthenticationPrincipal CikguUser user,
                             @PathVariable long goalId, RedirectAttributes flash) {
        goals.delete(goalId, user.getUserId());
        flash.addFlashAttribute("msg", "Goal deleted.");
        return "redirect:/learner/goals";
    }

    // ------------------------------------------------------------------
    // Module browsing + enrollment (bridge entity #1)
    // ------------------------------------------------------------------

    @GetMapping("/modules")
    public String browseModules(@AuthenticationPrincipal CikguUser user,
                                @RequestParam(required = false) String q,
                                @RequestParam(required = false) String difficulty,
                                Model model) {
        model.addAttribute("modules", modules.search(q, difficulty));
        model.addAttribute("q", q);
        model.addAttribute("difficulty", difficulty);
        model.addAttribute("myGoals", goals.findByLearner(user.getUserId()));
        return "learner/modules";
    }

    @PostMapping("/enroll")
    public String enroll(@AuthenticationPrincipal CikguUser user,
                         @RequestParam long moduleId,
                         @RequestParam(required = false) Long goalId,
                         RedirectAttributes flash) {
        if (enrollments.exists(user.getUserId(), moduleId)) {
            flash.addFlashAttribute("err", "You are already enrolled in that module.");
            return "redirect:/learner/modules";
        }
        if (goalId != null) {
            Goal goal = goals.findById(goalId).orElse(null);
            if (goal == null || goal.userId() != user.getUserId()) {
                flash.addFlashAttribute("err", "Choose one of your own goals.");
                return "redirect:/learner/modules";
            }
        }
        try {
            enrollments.enroll(user.getUserId(), moduleId, goalId);
            flash.addFlashAttribute("msg", "Enrolled successfully.");
        } catch (DuplicateKeyException e) {
            flash.addFlashAttribute("err", "You are already enrolled in that module.");
        }
        return "redirect:/learner/enrollments";
    }

    @GetMapping("/enrollments")
    public String enrollmentList(@AuthenticationPrincipal CikguUser user, Model model) {
        model.addAttribute("enrollments", enrollments.findByLearner(user.getUserId()));
        return "learner/enrollments";
    }

    @PostMapping("/enrollments/{moduleId}/drop")
    public String dropEnrollment(@AuthenticationPrincipal CikguUser user,
                                 @PathVariable long moduleId, RedirectAttributes flash) {
        enrollments.delete(user.getUserId(), moduleId);
        flash.addFlashAttribute("msg", "Enrollment cancelled.");
        return "redirect:/learner/enrollments";
    }
}
