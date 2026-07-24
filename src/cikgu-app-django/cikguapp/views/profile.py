"""
Inheritance demo screen — port of ProfileController.java. The profile page
joins the APP_USER superclass row with its LEARNER/TUTOR subclass row, and
editing updates both in one transaction.
"""

from django.contrib import messages
from django.db import transaction
from django.shortcuts import redirect, render
from django.views.decorators.http import require_http_methods

from ..auth import login_required
from ..repositories import users as users_repo


@login_required
@require_http_methods(["GET", "POST"])
def profile(request):
    user_id = request.cikgu_user["user_id"]

    if request.method == "POST":
        full_name = request.POST.get("fullName", "").strip()
        phone = request.POST.get("phone") or None
        education_background = request.POST.get("educationBackground") or None
        parsed_skills = request.POST.get("parsedSkills") or None
        expertise = request.POST.get("expertise") or None
        years_experience_raw = request.POST.get("yearsExperience") or None
        years_experience = int(years_experience_raw) if years_experience_raw else None

        if not full_name:
            messages.error(request, "Full name is required.")
            return redirect("profile")

        with transaction.atomic():
            users_repo.update_app_user(user_id, full_name, phone)
            if request.cikgu_user["user_type"] == "LEARNER":
                users_repo.update_learner(user_id, education_background, parsed_skills)
            else:
                users_repo.update_tutor(user_id, expertise, years_experience)

        messages.success(request, "Profile updated.")
        return redirect("profile")

    return render(request, "cikguapp/profile.html", {"profile": users_repo.find_profile(user_id)})
