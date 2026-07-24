"""Ad hoc read-only SQL console, available to both roles — port of ConsoleController.java."""

from django.db import Error as DatabaseError
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

from .. import console as console_service
from ..auth import login_required

DEFAULT_SQL = "SELECT module_title, difficulty, duration_hours FROM module ORDER BY module_title"


@login_required
@require_http_methods(["GET", "POST"])
def console(request):
    if request.method == "POST":
        sql = request.POST.get("sql", "")
        context = {"sql": sql}
        try:
            context["result"] = console_service.run(sql)
        except console_service.ConsoleError as e:
            context["console_error"] = str(e)
        except DatabaseError as e:
            context["console_error"] = f"Oracle error: {e}"
        return render(request, "cikguapp/console.html", context)

    return render(request, "cikguapp/console.html", {"sql": DEFAULT_SQL})
