package com.cikgu.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.cikgu.repository.UserRepository;
import com.cikgu.security.CikguUser;

/**
 * Inheritance demo screen: the profile page joins the APP_USER superclass
 * row with its LEARNER/TUTOR subclass row, and editing updates both.
 */
@Controller
public class ProfileController {

    private final UserRepository users;

    public ProfileController(UserRepository users) {
        this.users = users;
    }

    @GetMapping("/profile")
    public String profile(@AuthenticationPrincipal CikguUser user, Model model) {
        model.addAttribute("profile", users.findProfile(user.getUserId()).orElseThrow());
        return "profile";
    }

    @PostMapping("/profile")
    @Transactional
    public String updateProfile(@AuthenticationPrincipal CikguUser user,
                                @RequestParam String fullName,
                                @RequestParam(required = false) String phone,
                                @RequestParam(required = false) String educationBackground,
                                @RequestParam(required = false) String parsedSkills,
                                @RequestParam(required = false) String expertise,
                                @RequestParam(required = false) Integer yearsExperience,
                                RedirectAttributes flash) {
        if (fullName.isBlank()) {
            flash.addFlashAttribute("err", "Full name is required.");
            return "redirect:/profile";
        }
        users.updateAppUser(user.getUserId(), fullName.trim(), phone);
        if ("LEARNER".equals(user.getUserType())) {
            users.updateLearner(user.getUserId(), educationBackground, parsedSkills);
        } else {
            users.updateTutor(user.getUserId(), expertise, yearsExperience);
        }
        flash.addFlashAttribute("msg", "Profile updated.");
        return "redirect:/profile";
    }
}
