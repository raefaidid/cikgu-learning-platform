"""
The two transaction-management demos (graded): both wrap a multi-statement
write in django.db.transaction.atomic() so a failure midway rolls back
everything, mirroring the Spring Boot app's @Transactional services.
"""

from django.db import transaction

from . import auth
from .repositories import module_tutors as module_tutors_repo
from .repositories import modules as modules_repo
from .repositories import users as users_repo


class RegistrationError(Exception):
    pass


@transaction.atomic
def register(
    full_name,
    email,
    raw_password,
    phone,
    user_type,
    education_background,
    parsed_skills,
    expertise,
    years_experience,
):
    """
    The APP_USER superclass row and the matching subclass row (LEARNER or
    TUTOR) are inserted in ONE transaction — if either insert fails, both
    roll back and no orphan superclass row is left behind.
    """
    if users_repo.email_exists(email):
        raise RegistrationError("An account with that email already exists.")
    if user_type not in ("LEARNER", "TUTOR"):
        raise RegistrationError("Account type must be LEARNER or TUTOR.")

    user_id = users_repo.next_user_id()
    users_repo.insert_app_user(
        user_id, full_name, email, auth.hash_password(raw_password), phone, user_type
    )

    if user_type == "LEARNER":
        users_repo.insert_learner(user_id, education_background, parsed_skills)
    else:
        users_repo.insert_tutor(user_id, expertise, years_experience)
    return user_id


@transaction.atomic
def create_module(lead_tutor_id, title, description, duration_hours, difficulty):
    """
    Creating a module and its LEAD assignment is one transaction: every
    module must have exactly one LEAD tutor (enforced by the
    modtut_one_lead_uix function-based unique index).
    """
    module_id = modules_repo.next_module_id()
    modules_repo.insert(module_id, title, description, duration_hours, difficulty)
    module_tutors_repo.assign(module_id, lead_tutor_id, "LEAD")
    return module_id
