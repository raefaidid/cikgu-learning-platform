def cikgu_user(request):
    """Expose the logged-in user (or None) to every template, for the nav bar."""
    return {"cikgu_user": getattr(request, "cikgu_user", None)}
