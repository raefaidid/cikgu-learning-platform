"""Attaches request.cikgu_user from the session on every request."""


class CikguUserMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.cikgu_user = request.session.get("cikgu_user")
        return self.get_response(request)
