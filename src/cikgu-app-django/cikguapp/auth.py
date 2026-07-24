"""
Session-based authentication against the app_user table — the Django
equivalent of the Spring Boot app's CikguUserDetailsService + SecurityConfig,
minus Spring Security itself. No django.contrib.auth User model is involved;
the "logged-in user" is just a small dict (user_id, full_name, email,
user_type) stored in the signed-cookie session.

Passwords are bcrypt (compatible with the seed data and with the original
app's Spring BCryptPasswordEncoder — both produce/verify standard $2a$/$2b$
hashes).
"""

from functools import wraps

import bcrypt
from django.contrib import messages
from django.shortcuts import redirect

from . import db

SESSION_KEY = "cikgu_user"


def find_user_by_email(email):
    return db.query_one(
        """
        SELECT user_id, full_name, email, password_hash, user_type
          FROM app_user
         WHERE LOWER(email) = LOWER(%s)
        """,
        [email],
    )


def check_password(raw_password, password_hash):
    return bcrypt.checkpw(raw_password.encode("utf-8"), password_hash.encode("utf-8"))


def hash_password(raw_password):
    return bcrypt.hashpw(raw_password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def authenticate(email, raw_password):
    """Return the app_user row if email/password match, else None."""
    row = find_user_by_email(email)
    if row is None:
        return None
    if not check_password(raw_password, row["password_hash"]):
        return None
    return row


def login_user(request, user_row):
    request.session.cycle_key()  # session-fixation protection, same intent as Spring Security
    request.session[SESSION_KEY] = {
        "user_id": user_row["user_id"],
        "full_name": user_row["full_name"],
        "email": user_row["email"],
        "user_type": user_row["user_type"],
    }
    request.cikgu_user = request.session[SESSION_KEY]


def logout_user(request):
    request.session.flush()
    request.cikgu_user = None


def login_required(view):
    """Equivalent of SecurityConfig's .anyRequest().authenticated()."""

    @wraps(view)
    def wrapped(request, *args, **kwargs):
        if request.cikgu_user is None:
            return redirect("login")
        return view(request, *args, **kwargs)

    return wrapped


def role_required(user_type):
    """Equivalent of SecurityConfig's hasRole('LEARNER') / hasRole('TUTOR')."""

    def decorator(view):
        @wraps(view)
        @login_required
        def wrapped(request, *args, **kwargs):
            if request.cikgu_user["user_type"] != user_type:
                messages.error(request, "You don't have access to that page.")
                return redirect("home")
            return view(request, *args, **kwargs)

        return wrapped

    return decorator
