"""URL configuration for the cikgu project — delegates everything to cikguapp."""

from django.urls import include, path

urlpatterns = [
    path("", include("cikguapp.urls")),
]
