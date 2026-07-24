"""
Django settings for the Cikgu Personalized Learning Platform.

Deliberate mirror of the Spring Boot app's application.properties: all data
access is hand-written SQL through django.db.connection (see cikguapp/db.py)
against the same CIKGU Oracle schema — no Django ORM models, no
django.contrib.auth, no Django-managed database tables at all. Sessions are
signed cookies, so this app never creates or touches anything in Oracle
beyond the CIKGU schema objects created by schema/cikgu/cikgu_install.sql.
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get(
    "CIKGU_SECRET_KEY",
    "django-insecure-cikgu-dev-key-change-me-for-production",
)

DEBUG = os.environ.get("CIKGU_DEBUG", "1") == "1"

ALLOWED_HOSTS = os.environ.get("CIKGU_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")

INSTALLED_APPS = [
    # No django.contrib.admin/auth/contenttypes: this app rolls its own
    # session-based auth against the app_user table (see cikguapp/auth.py)
    # and never asks Django to manage a table of its own.
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "cikguapp",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "cikguapp.middleware.CikguUserMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "cikgu.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.messages.context_processors.messages",
                "cikguapp.context_processors.cikgu_user",
            ],
        },
    },
]

WSGI_APPLICATION = "cikgu.wsgi.application"

# Database ---------------------------------------------------------------
# Same target as the JDBC URL jdbc:oracle:thin:@//localhost:1521/FREEPDB1,
# user cikgu / Cikgu_123, against the CIKGU schema installed by
# schema/cikgu/cikgu_install.sql.
#
# FREEPDB1 is a service name, not a SID. Django's oracledb backend only
# builds an Easy Connect (host:port/service_name) string when HOST/PORT are
# left unset and NAME carries the whole thing -- if HOST/PORT are set
# separately, it builds a SID-style DSN instead (Database.makedsn(host,
# port, sid)), which fails against a service-name-only listener entry with
# "DPY-6003: SID ... is not registered with the listener". So NAME is
# assembled here from the three env vars instead of passing them through
# as separate HOST/PORT/NAME keys.
_db_host = os.environ.get("CIKGU_DB_HOST", "localhost")
_db_port = os.environ.get("CIKGU_DB_PORT", "1521")
_db_service = os.environ.get("CIKGU_DB_SERVICE", "FREEPDB1")

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.oracle",
        "NAME": f"{_db_host}:{_db_port}/{_db_service}",
        "USER": os.environ.get("CIKGU_DB_USER", "cikgu"),
        "PASSWORD": os.environ.get("CIKGU_DB_PASSWORD", "Cikgu_123"),
    }
}

# Sessions / flash messages -----------------------------------------------
# Signed cookies: no server-side session table, so Django never manages any
# storage of its own in the CIKGU-only Oracle schema.
SESSION_ENGINE = "django.contrib.sessions.backends.signed_cookies"
SESSION_COOKIE_AGE = 60 * 60 * 8  # 8 hours, like a typical browser session
MESSAGE_STORAGE = "django.contrib.messages.storage.session.SessionStorage"

from django.contrib.messages import constants as message_constants  # noqa: E402

# Map Django's message levels onto the existing .flash.ok / .flash.err CSS
# classes carried over from the Spring Boot app's stylesheet.
MESSAGE_TAGS = {
    message_constants.SUCCESS: "ok",
    message_constants.ERROR: "err",
    message_constants.WARNING: "err",
}

# Internationalization -----------------------------------------------------
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

# Static files ---------------------------------------------------------
STATIC_URL = "static/"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

LOGIN_URL = "login"
