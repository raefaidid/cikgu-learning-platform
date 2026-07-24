"""Reporting dashboard, available to both roles — port of ReportController.java."""

from django.shortcuts import render

from ..auth import login_required
from ..repositories import reports as reports_repo


@login_required
def reports(request):
    top_modules = reports_repo.top_modules()
    context = {
        "top_modules": top_modules,
        "chart_data": {
            "labels": [m["module_title"] for m in top_modules],
            "values": [float(m["avg_progress"] or 0) for m in top_modules],
        },
        "behind_schedule": reports_repo.behind_schedule(),
    }
    return render(request, "cikguapp/reports.html", context)
