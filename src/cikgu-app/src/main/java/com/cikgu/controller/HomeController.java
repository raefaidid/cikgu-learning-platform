package com.cikgu.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.cikgu.security.CikguUser;
import com.cikgu.service.RegistrationService;

@Controller
public class HomeController {

    private final RegistrationService registrationService;

    public HomeController(RegistrationService registrationService) {
        this.registrationService = registrationService;
    }

    @GetMapping("/")
    public String home(@AuthenticationPrincipal CikguUser user) {
        if (user == null) {
            return "redirect:/login";
        }
        return "LEARNER".equals(user.getUserType())
                ? "redirect:/learner/dashboard"
                : "redirect:/tutor/dashboard";
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }

    @GetMapping("/register")
    public String registerForm() {
        return "register";
    }

    /**
     * Inheritance + transaction demo: one form creates the APP_USER
     * superclass row and the LEARNER/TUTOR subclass row atomically
     * (see RegistrationService#register).
     */
    @PostMapping("/register")
    public String register(@RequestParam String fullName,
                           @RequestParam String email,
                           @RequestParam String password,
                           @RequestParam(required = false) String phone,
                           @RequestParam String userType,
                           @RequestParam(required = false) String educationBackground,
                           @RequestParam(required = false) String parsedSkills,
                           @RequestParam(required = false) String expertise,
                           @RequestParam(required = false) Integer yearsExperience,
                           RedirectAttributes flash) {
        try {
            if (fullName.isBlank() || email.isBlank() || password.length() < 8) {
                throw new IllegalArgumentException(
                        "Name and email are required, and the password needs at least 8 characters.");
            }
            registrationService.register(fullName.trim(), email.trim(), password, phone,
                    userType, educationBackground, parsedSkills, expertise, yearsExperience);
            flash.addFlashAttribute("msg", "Account created. Please log in.");
            return "redirect:/login";
        } catch (IllegalArgumentException e) {
            flash.addFlashAttribute("err", e.getMessage());
            return "redirect:/register";
        }
    }
}
