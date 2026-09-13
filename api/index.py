import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.main import app as fastapi_app  # noqa: E402


async def app(scope, receive, send):
    """Expose FastAPI to Vercel serverless.

    Newer Vercel routing forwards the *rewritten* path (/api/index...)
    to the function instead of the original URL, so strip that prefix
    to restore the real route. Local uvicorn runs are unaffected.
    """
    if scope.get("type") == "http":
        path = scope.get("path", "")
        for prefix in ("/api/index", "/api"):
            if path == prefix or path.startswith(prefix + "/"):
                scope["path"] = path[len(prefix):] or "/"
                break
    await fastapi_app(scope, receive, send)
