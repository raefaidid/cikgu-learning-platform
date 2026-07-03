package com.cikgu.controller;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.cikgu.model.LearningModule;
import com.cikgu.repository.EnrollmentRepository;
import com.cikgu.repository.ModuleRepository;
import com.cikgu.repository.ModuleTutorRepository;
import com.cikgu.repository.UserRepository;
import com.cikgu.security.CikguUser;
import com.cikgu.service.ModuleService;

@Controller
@RequestMapping("/tutor")
public class TutorController {

    private final ModuleRepository modules;
    private final ModuleTutorRepository moduleTutors;
    private final EnrollmentRepository enrollments;
    private final UserRepository users;
    private final ModuleService moduleService;

    public TutorController(ModuleRepository modules, ModuleTutorRepository moduleTutors,
                           EnrollmentRepository enrollments, UserRepository users,
                           ModuleService moduleService) {
        this.modules = modules;
        this.moduleTutors = moduleTutors;
        this.enrollments = enrollments;
        this.users = users;
        this.moduleService = moduleService;
    }

    @GetMapping("/dashboard")
    public String dashboard(@AuthenticationPrincipal CikguUser user, Model model) {
        model.addAttribute("modules", modules.findByTutor(user.getUserId()));
        model.addAttribute("mentees", users.directMentees(user.getUserId()));
        return "tutor/dashboard";
    }

    // ------------------------------------------------------------------
    // Module management (create / edit / delete)
    // ------------------------------------------------------------------

    @GetMapping("/modules")
    public String myModules(@AuthenticationPrincipal CikguUser user, Model model) {
        model.addAttribute("modules", modules.findByTutor(user.getUserId()));
        return "tutor/modules";
    }

    @GetMapping("/modules/new")
    public String newModuleForm() {
        return "tutor/module-new";
    }

    @PostMapping("/modules")
    public String createModule(@AuthenticationPrincipal CikguUser user,
                               @RequestParam String moduleTitle,
                               @RequestParam(required = false) String description,
                               @RequestParam(required = false) Integer durationHours,
                               @RequestParam String difficulty,
                               RedirectAttributes flash) {
        if (moduleTitle.isBlank()) {
            flash.addFlashAttribute("err", "Module title is required.");
            return "redirect:/tutor/modules/new";
        }
        moduleService.createModule(user.getUserId(), moduleTitle.trim(),
                description, durationHours, difficulty);
        flash.addFlashAttribute("msg", "Module created — you are its LEAD tutor.");
        return "redirect:/tutor/modules";
    }

    @GetMapping("/modules/{moduleId}/edit")
    public String editModuleForm(@AuthenticationPrincipal CikguUser user,
                                 @PathVariable long moduleId, Model model,
                                 RedirectAttributes flash) {
        if (!moduleTutors.teaches(user.getUserId(), moduleId)) {
            flash.addFlashAttribute("err", "You can only edit modules you teach.");
            return "redirect:/tutor/modules";
        }
        LearningModule module = modules.findById(moduleId).orElse(null);
        if (module == null) {
            flash.addFlashAttribute("err", "Module not found.");
            return "redirect:/tutor/modules";
        }
        model.addAttribute("module", module);
        return "tutor/module-edit";
    }

    @PostMapping("/modules/{moduleId}/edit")
    public String updateModule(@AuthenticationPrincipal CikguUser user,
                               @PathVariable long moduleId,
                               @RequestParam String moduleTitle,
                               @RequestParam(required = false) String description,
                               @RequestParam(required = false) Integer durationHours,
                               @RequestParam String difficulty,
                               RedirectAttributes flash) {
        if (!moduleTutors.teaches(user.getUserId(), moduleId)) {
            flash.addFlashAttribute("err", "You can only edit modules you teach.");
            return "redirect:/tutor/modules";
        }
        modules.update(moduleId, moduleTitle.trim(), description, durationHours, difficulty);
        flash.addFlashAttribute("msg", "Module updated.");
        return "redirect:/tutor/modules";
    }

    @PostMapping("/modules/{moduleId}/delete")
    public String deleteModule(@AuthenticationPrincipal CikguUser user,
                               @PathVariable long moduleId, RedirectAttributes flash) {
        if (!moduleTutors.teaches(user.getUserId(), moduleId)) {
            flash.addFlashAttribute("err", "You can only delete modules you teach.");
            return "redirect:/tutor/modules";
        }
        modules.delete(moduleId);
        flash.addFlashAttribute("msg", "Module deleted (enrollments and tutor assignments removed by cascade).");
        return "redirect:/tutor/modules";
    }

    // ------------------------------------------------------------------
    // Co-teacher management (bridge entity #2: MODULE_TUTOR)
    // ------------------------------------------------------------------

    @GetMapping("/modules/{moduleId}/teachers")
    public String coTeachers(@AuthenticationPrincipal CikguUser user,
                             @PathVariable long moduleId, Model model,
                             RedirectAttributes flash) {
        if (!moduleTutors.teaches(user.getUserId(), moduleId)) {
            flash.addFlashAttribute("err", "You can only manage modules you teach.");
            return "redirect:/tutor/modules";
        }
        model.addAttribute("module", modules.findById(moduleId).orElseThrow());
        model.addAttribute("teachers", moduleTutors.findByModule(moduleId));
        model.addAttribute("candidates", moduleTutors.tutorsNotOnModule(moduleId));
        return "tutor/co-teachers";
    }

    @PostMapping("/modules/{moduleId}/teachers")
    public String addCoTeacher(@AuthenticationPrincipal CikguUser user,
                               @PathVariable long moduleId,
                               @RequestParam long tutorId,
                               RedirectAttributes flash) {
        if (!moduleTutors.teaches(user.getUserId(), moduleId)) {
            flash.addFlashAttribute("err", "You can only manage modules you teach.");
            return "redirect:/tutor/modules";
        }
        try {
            moduleTutors.assign(moduleId, tutorId, "CO_TEACHER");
            flash.addFlashAttribute("msg", "Co-teacher added.");
        } catch (DuplicateKeyException e) {
            flash.addFlashAttribute("err", "That tutor is already assigned to this module.");
        }
        return "redirect:/tutor/modules/" + moduleId + "/teachers";
    }

    @PostMapping("/modules/{moduleId}/teachers/{tutorId}/remove")
    public String removeCoTeacher(@AuthenticationPrincipal CikguUser user,
                                  @PathVariable long moduleId,
                                  @PathVariable long tutorId,
                                  RedirectAttributes flash) {
        if (!moduleTutors.teaches(user.getUserId(), moduleId)) {
            flash.addFlashAttribute("err", "You can only manage modules you teach.");
            return "redirect:/tutor/modules";
        }
        int removed = moduleTutors.removeCoTeacher(moduleId, tutorId);
        flash.addFlashAttribute(removed > 0 ? "msg" : "err",
                removed > 0 ? "Co-teacher removed." : "The LEAD tutor cannot be removed.");
        return "redirect:/tutor/modules/" + moduleId + "/teachers";
    }

    // ------------------------------------------------------------------
    // Learner progress management
    // ------------------------------------------------------------------

    @GetMapping("/progress")
    public String progress(@AuthenticationPrincipal CikguUser user, Model model) {
        model.addAttribute("enrollments", enrollments.findByTutor(user.getUserId()));
        return "tutor/progress";
    }

    @PostMapping("/progress")
    public String updateProgress(@AuthenticationPrincipal CikguUser user,
                                 @RequestParam long learnerId,
                                 @RequestParam long moduleId,
                                 @RequestParam double progressScore,
                                 @RequestParam String status,
                                 RedirectAttributes flash) {
        if (!moduleTutors.teaches(user.getUserId(), moduleId)) {
            flash.addFlashAttribute("err", "You can only update learners in modules you teach.");
            return "redirect:/tutor/progress";
        }
        if (progressScore < 0 || progressScore > 100) {
            flash.addFlashAttribute("err", "Progress must be between 0 and 100.");
            return "redirect:/tutor/progress";
        }
        enrollments.updateProgress(learnerId, moduleId, progressScore, status);
        flash.addFlashAttribute("msg", "Progress updated (last_updated_at set by the database trigger).");
        return "redirect:/tutor/progress";
    }

    // ------------------------------------------------------------------
    // Mentorship (recursive relationship demo)
    // ------------------------------------------------------------------

    @GetMapping("/mentorship")
    public String mentorship(@AuthenticationPrincipal CikguUser user, Model model) {
        model.addAttribute("hierarchy", users.mentorshipHierarchy());
        model.addAttribute("candidates", users.eligibleMentors(user.getUserId()));
        model.addAttribute("me", users.findProfile(user.getUserId()).orElseThrow());
        return "tutor/mentorship";
    }

    @PostMapping("/mentorship")
    public String setMentor(@AuthenticationPrincipal CikguUser user,
                            @RequestParam(required = false) Long mentorId,
                            RedirectAttributes flash) {
        if (mentorId != null) {
            boolean eligible = users.eligibleMentors(user.getUserId()).stream()
                    .anyMatch(t -> t.userId() == mentorId);
            if (!eligible) {
                flash.addFlashAttribute("err",
                        "That tutor cannot be your mentor (it would create a cycle).");
                return "redirect:/tutor/mentorship";
            }
        }
        users.updateMentor(user.getUserId(), mentorId);
        flash.addFlashAttribute("msg", mentorId == null ? "Mentor cleared." : "Mentor assigned.");
        return "redirect:/tutor/mentorship";
    }
}
