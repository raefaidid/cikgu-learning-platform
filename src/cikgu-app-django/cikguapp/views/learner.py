"""Learner-facing views — port of LearnerController.java."""

from django.contrib import messages
from django.db import IntegrityError
from django.shortcuts import redirect, render
from django.utils.dateparse import parse_date
from django.views.decorators.http import require_http_methods

from ..auth import role_required
from ..repositories import enrollments as enrollments_repo
from ..repositories import goals as goals_repo
from ..repositories import modules as modules_repo


@role_required("LEARNER")
def dashboard(request):
    user_id = request.cikgu_user["user_id"]
    enrollments = enrollments_repo.find_by_learner(user_id)
    context = {
        "goals": goals_repo.find_by_learner(user_id),
        "enrollments": enrollments,
        "completed_count": sum(1 for e in enrollments if e["status"] == "COMPLETED"),
        "behind_count": sum(1 for e in enrollments if e["behind_schedule"]),
    }
    return render(request, "cikguapp/learner/dashboard.html", context)


# ----------------------------------------------------------------------
# Goal management (create / edit / delete)
# ----------------------------------------------------------------------


@role_required("LEARNER")
@require_http_methods(["GET", "POST"])
def goals(request):
    user_id = request.cikgu_user["user_id"]
    if request.method == "POST":
        title = request.POST.get("goalTitle", "").strip()
        outcome = request.POST.get("targetOutcome") or None
        target_date = parse_date(request.POST.get("targetDate") or "")
        if not title:
            messages.error(request, "Goal title is required.")
            return redirect("learner_goals")
        goals_repo.insert(user_id, title, outcome, target_date)
        messages.success(request, "Goal created.")
        return redirect("learner_goals")

    return render(request, "cikguapp/learner/goals.html", {"goals": goals_repo.find_by_learner(user_id)})


@role_required("LEARNER")
@require_http_methods(["GET", "POST"])
def goal_edit(request, goal_id):
    user_id = request.cikgu_user["user_id"]

    if request.method == "POST":
        title = request.POST.get("goalTitle", "").strip()
        outcome = request.POST.get("targetOutcome") or None
        target_date = parse_date(request.POST.get("targetDate") or "")
        goals_repo.update(goal_id, user_id, title, outcome, target_date)
        messages.success(request, "Goal updated.")
        return redirect("learner_goals")

    goal = goals_repo.find_by_id(goal_id)
    if goal is None or goal["user_id"] != user_id:
        messages.error(request, "Goal not found.")
        return redirect("learner_goals")
    return render(request, "cikguapp/learner/goal_edit.html", {"goal": goal})


@role_required("LEARNER")
@require_http_methods(["POST"])
def goal_delete(request, goal_id):
    goals_repo.delete(goal_id, request.cikgu_user["user_id"])
    messages.success(request, "Goal deleted.")
    return redirect("learner_goals")


# ----------------------------------------------------------------------
# Module browsing + enrollment (bridge entity #1)
# ----------------------------------------------------------------------


@role_required("LEARNER")
def browse_modules(request):
    user_id = request.cikgu_user["user_id"]
    q = request.GET.get("q") or None
    difficulty = request.GET.get("difficulty") or None
    context = {
        "modules": modules_repo.search(q, difficulty),
        "q": q or "",
        "difficulty": difficulty or "",
        "my_goals": goals_repo.find_by_learner(user_id),
    }
    return render(request, "cikguapp/learner/modules.html", context)


@role_required("LEARNER")
@require_http_methods(["POST"])
def enroll(request):
    user_id = request.cikgu_user["user_id"]
    module_id = int(request.POST["moduleId"])
    goal_id_raw = request.POST.get("goalId") or None
    goal_id = int(goal_id_raw) if goal_id_raw else None

    if enrollments_repo.exists(user_id, module_id):
        messages.error(request, "You are already enrolled in that module.")
        return redirect("learner_modules")

    if goal_id is not None:
        goal = goals_repo.find_by_id(goal_id)
        if goal is None or goal["user_id"] != user_id:
            messages.error(request, "Choose one of your own goals.")
            return redirect("learner_modules")

    try:
        enrollments_repo.enroll(user_id, module_id, goal_id)
        messages.success(request, "Enrolled successfully.")
    except IntegrityError:
        messages.error(request, "You are already enrolled in that module.")
    return redirect("learner_enrollments")


@role_required("LEARNER")
def enrollment_list(request):
    enrollments = enrollments_repo.find_by_learner(request.cikgu_user["user_id"])
    return render(request, "cikguapp/learner/enrollments.html", {"enrollments": enrollments})


@role_required("LEARNER")
@require_http_methods(["POST"])
def drop_enrollment(request, module_id):
    enrollments_repo.delete(request.cikgu_user["user_id"], module_id)
    messages.success(request, "Enrollment cancelled.")
    return redirect("learner_enrollments")
