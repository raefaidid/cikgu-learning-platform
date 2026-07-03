package com.cikgu.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cikgu.repository.ModuleRepository;
import com.cikgu.repository.ModuleTutorRepository;

@Service
public class ModuleService {

    private final ModuleRepository modules;
    private final ModuleTutorRepository moduleTutors;

    public ModuleService(ModuleRepository modules, ModuleTutorRepository moduleTutors) {
        this.modules = modules;
        this.moduleTutors = moduleTutors;
    }

    /**
     * Creating a module and its LEAD assignment is one transaction: every
     * module must have exactly one LEAD tutor (enforced by the
     * modtut_one_lead_uix function-based unique index).
     */
    @Transactional
    public long createModule(long leadTutorId, String title, String description,
                             Integer durationHours, String difficulty) {
        long moduleId = modules.nextModuleId();
        modules.insert(moduleId, title, description, durationHours, difficulty);
        moduleTutors.assign(moduleId, leadTutorId, "LEAD");
        return moduleId;
    }
}
