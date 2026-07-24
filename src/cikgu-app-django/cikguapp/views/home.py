"""Home redirect, login, logout, register — port of HomeController.java."""

from django.contrib import messages
from django.shortcuts import redirect, render
from django.views.decorators.http import require_http_methods

from .. import auth, services


def home(request):
    user = request.cikgu_user
    if user is None:
        return redirect("login")
    return redirect("learner_dashboard" if user["user_type"] == "LEARNER" else "tutor_dashboard")


@require_http_methods(["GET", "POST"])
def login_view(request):
    if request.method == "POST":
        email = request.POST.get("username", "").strip()
        password = request.POST.get("password", "")
        user_row = auth.authenticate(email, password)
        if user_row is None:
            messages.error(request, "Invalid email or password.")
            return redirect("login")
        auth.login_user(request, user_row)
        return redirect("home")
    return render(request, "cikguapp/login.html")


@require_http_methods(["POST"])
def logout_view(request):
    auth.logout_user(request)
    messages.success(request, "You have been logged out.")
    return redirect("login")


@require_http_methods(["GET", "POST"])
def register_view(request):
    if request.method == "POST":
        full_name = request.POST.get("fullName", "").strip()
        email = request.POST.get("email", "").strip()
        password = request.POST.get("password", "")
        phone = request.POST.get("phone") or None
        user_type = request.POST.get("userType", "")
        education_background = request.POST.get("educationBackground") or None
        parsed_skills = request.POST.get("parsedSkills") or None
        expertise = request.POST.get("expertise") or None
        years_experience_raw = request.POST.get("yearsExperience") or None
        years_experience = int(years_experience_raw) if years_experience_raw else None

        if not full_name or not email or len(password) < 8:
            messages.error(
                request,
                "Name and email are required, and the password needs at least 8 characters.",
            )
            return redirect("register")

        try:
            services.register(
                full_name,
                email,
                password,
                phone,
                user_type,
                education_background,
                parsed_skills,
                expertise,
                years_experience,
            )
        except services.RegistrationError as e:
            messages.error(request, str(e))
            return redirect("register")

        messages.success(request, "Account created. Please log in.")
        return redirect("login")
    return render(request, "cikguapp/register.html")
