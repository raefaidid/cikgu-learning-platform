from django.urls import path

from .views import console, home, learner, profile, reports, tutor

urlpatterns = [
    path("", home.home, name="home"),
    path("login/", home.login_view, name="login"),
    path("logout/", home.logout_view, name="logout"),
    path("register/", home.register_view, name="register"),
    path("profile/", profile.profile, name="profile"),
    path("reports/", reports.reports, name="reports"),
    path("console/", console.console, name="console"),
    # Learner ------------------------------------------------------------
    path("learner/dashboard/", learner.dashboard, name="learner_dashboard"),
    path("learner/goals/", learner.goals, name="learner_goals"),
    path("learner/goals/<int:goal_id>/edit/", learner.goal_edit, name="learner_goal_edit"),
    path("learner/goals/<int:goal_id>/delete/", learner.goal_delete, name="learner_goal_delete"),
    path("learner/modules/", learner.browse_modules, name="learner_modules"),
    path("learner/enroll/", learner.enroll, name="learner_enroll"),
    path("learner/enrollments/", learner.enrollment_list, name="learner_enrollments"),
    path(
        "learner/enrollments/<int:module_id>/drop/",
        learner.drop_enrollment,
        name="learner_enrollment_drop",
    ),
    # Tutor ----------------------------------------------------------------
    path("tutor/dashboard/", tutor.dashboard, name="tutor_dashboard"),
    path("tutor/modules/", tutor.my_modules, name="tutor_modules"),
    path("tutor/modules/new/", tutor.new_module_form, name="tutor_new_module"),
    path("tutor/modules/create/", tutor.create_module, name="tutor_create_module"),
    path("tutor/modules/<int:module_id>/edit/", tutor.module_edit, name="tutor_module_edit"),
    path("tutor/modules/<int:module_id>/delete/", tutor.module_delete, name="tutor_module_delete"),
    path("tutor/modules/<int:module_id>/teachers/", tutor.co_teachers, name="tutor_co_teachers"),
    path(
        "tutor/modules/<int:module_id>/teachers/<int:tutor_id>/remove/",
        tutor.remove_co_teacher,
        name="tutor_remove_co_teacher",
    ),
    path("tutor/progress/", tutor.progress, name="tutor_progress"),
    path("tutor/progress/update/", tutor.update_progress, name="tutor_update_progress"),
    path("tutor/mentorship/", tutor.mentorship, name="tutor_mentorship"),
    path("tutor/mentorship/set/", tutor.set_mentor, name="tutor_set_mentor"),
]
