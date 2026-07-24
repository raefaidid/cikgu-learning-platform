"""Tutor-facing views — port of TutorController.java."""

from django.contrib import messages
from django.db import IntegrityError
from django.shortcuts import redirect, render
from django.views.decorators.http import require_http_methods

from .. import services
from ..auth import role_required
from ..repositories import enrollments as enrollments_repo
from ..repositories import module_tutors as module_tutors_repo
from ..repositories import modules as modules_repo
from ..repositories import users as users_repo


@role_required("TUTOR")
def dashboard(request):
    user_id = request.cikgu_user["user_id"]
    context = {
        "modules": modules_repo.find_by_tutor(user_id),
        "mentees": users_repo.direct_mentees(user_id),
    }
    return render(request, "cikguapp/tutor/dashboard.html", context)


# ----------------------------------------------------------------------
# Module management (create / edit / delete)
# ----------------------------------------------------------------------


@role_required("TUTOR")
def my_modules(request):
    modules = modules_repo.find_by_tutor(request.cikgu_user["user_id"])
    return render(request, "cikguapp/tutor/modules.html", {"modules": modules})


@role_required("TUTOR")
def new_module_form(request):
    return render(request, "cikguapp/tutor/module_new.html")


@role_required("TUTOR")
@require_http_methods(["POST"])
def create_module(request):
    title = request.POST.get("moduleTitle", "").strip()
    description = request.POST.get("description") or None
    duration_hours_raw = request.POST.get("durationHours") or None
    duration_hours = int(duration_hours_raw) if duration_hours_raw else None
    difficulty = request.POST.get("difficulty", "")

    if not title:
        messages.error(request, "Module title is required.")
        return redirect("tutor_new_module")

    services.create_module(request.cikgu_user["user_id"], title, description, duration_hours, difficulty)
    messages.success(request, "Module created — you are its LEAD tutor.")
    return redirect("tutor_modules")


@role_required("TUTOR")
@require_http_methods(["GET", "POST"])
def module_edit(request, module_id):
    user_id = request.cikgu_user["user_id"]
    if not module_tutors_repo.teaches(user_id, module_id):
        messages.error(request, "You can only edit modules you teach.")
        return redirect("tutor_modules")

    if request.method == "POST":
        title = request.POST.get("moduleTitle", "").strip()
        description = request.POST.get("description") or None
        duration_hours_raw = request.POST.get("durationHours") or None
        duration_hours = int(duration_hours_raw) if duration_hours_raw else None
        difficulty = request.POST.get("difficulty", "")
        modules_repo.update(module_id, title, description, duration_hours, difficulty)
        messages.success(request, "Module updated.")
        return redirect("tutor_modules")

    module = modules_repo.find_by_id(module_id)
    if module is None:
        messages.error(request, "Module not found.")
        return redirect("tutor_modules")
    return render(request, "cikguapp/tutor/module_edit.html", {"module": module})


@role_required("TUTOR")
@require_http_methods(["POST"])
def module_delete(request, module_id):
    if not module_tutors_repo.teaches(request.cikgu_user["user_id"], module_id):
        messages.error(request, "You can only delete modules you teach.")
        return redirect("tutor_modules")
    modules_repo.delete(module_id)
    messages.success(request, "Module deleted (enrollments and tutor assignments removed by cascade).")
    return redirect("tutor_modules")


# ----------------------------------------------------------------------
# Co-teacher management (bridge entity #2: MODULE_TUTOR)
# ----------------------------------------------------------------------


@role_required("TUTOR")
@require_http_methods(["GET", "POST"])
def co_teachers(request, module_id):
    user_id = request.cikgu_user["user_id"]
    if not module_tutors_repo.teaches(user_id, module_id):
        messages.error(request, "You can only manage modules you teach.")
        return redirect("tutor_modules")

    if request.method == "POST":
        tutor_id = int(request.POST["tutorId"])
        try:
            module_tutors_repo.assign(module_id, tutor_id, "CO_TEACHER")
            messages.success(request, "Co-teacher added.")
        except IntegrityError:
            messages.error(request, "That tutor is already assigned to this module.")
        return redirect("tutor_co_teachers", module_id=module_id)

    context = {
        "module": modules_repo.find_by_id(module_id),
        "teachers": module_tutors_repo.find_by_module(module_id),
        "candidates": module_tutors_repo.tutors_not_on_module(module_id),
    }
    return render(request, "cikguapp/tutor/co_teachers.html", context)


@role_required("TUTOR")
@require_http_methods(["POST"])
def remove_co_teacher(request, module_id, tutor_id):
    if not module_tutors_repo.teaches(request.cikgu_user["user_id"], module_id):
        messages.error(request, "You can only manage modules you teach.")
        return redirect("tutor_modules")

    removed = module_tutors_repo.remove_co_teacher(module_id, tutor_id)
    if removed > 0:
        messages.success(request, "Co-teacher removed.")
    else:
        messages.error(request, "The LEAD tutor cannot be removed.")
    return redirect("tutor_co_teachers", module_id=module_id)


# ----------------------------------------------------------------------
# Learner progress management
# ----------------------------------------------------------------------


@role_required("TUTOR")
def progress(request):
    enrollments = enrollments_repo.find_by_tutor(request.cikgu_user["user_id"])
    return render(request, "cikguapp/tutor/progress.html", {"enrollments": enrollments})


@role_required("TUTOR")
@require_http_methods(["POST"])
def update_progress(request):
    user_id = request.cikgu_user["user_id"]
    learner_id = int(request.POST["learnerId"])
    module_id = int(request.POST["moduleId"])
    progress_score = float(request.POST["progressScore"])
    status = request.POST.get("status", "")

    if not module_tutors_repo.teaches(user_id, module_id):
        messages.error(request, "You can only update learners in modules you teach.")
        return redirect("tutor_progress")
    if not (0 <= progress_score <= 100):
        messages.error(request, "Progress must be between 0 and 100.")
        return redirect("tutor_progress")

    enrollments_repo.update_progress(learner_id, module_id, progress_score, status)
    messages.success(request, "Progress updated (last_updated_at set by the database trigger).")
    return redirect("tutor_progress")


# ----------------------------------------------------------------------
# Mentorship (recursive relationship demo)
# ----------------------------------------------------------------------


@role_required("TUTOR")
def mentorship(request):
    user_id = request.cikgu_user["user_id"]
    hierarchy = users_repo.mentorship_hierarchy()
    for node in hierarchy:
        # Indent depicting mentorship depth: 4 spaces per level plus a
        # corner glyph, same visual as the original "|__" tree rendering.
        node["indent"] = ("\xa0\xa0\xa0\xa0" * (node["tree_level"] - 1)) + "└ " if node["tree_level"] > 1 else ""
    context = {
        "hierarchy": hierarchy,
        "candidates": users_repo.eligible_mentors(user_id),
        "me": users_repo.find_profile(user_id),
    }
    return render(request, "cikguapp/tutor/mentorship.html", context)


@role_required("TUTOR")
@require_http_methods(["POST"])
def set_mentor(request):
    user_id = request.cikgu_user["user_id"]
    mentor_id_raw = request.POST.get("mentorId") or None
    mentor_id = int(mentor_id_raw) if mentor_id_raw else None

    if mentor_id is not None:
        eligible = any(t["user_id"] == mentor_id for t in users_repo.eligible_mentors(user_id))
        if not eligible:
            messages.error(request, "That tutor cannot be your mentor (it would create a cycle).")
            return redirect("tutor_mentorship")

    users_repo.update_mentor(user_id, mentor_id)
    messages.success(request, "Mentor cleared." if mentor_id is None else "Mentor assigned.")
    return redirect("tutor_mentorship")
