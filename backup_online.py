"""نسخة احتياطية من قاعدة البيانات المباشرة (Neon) إلى ملف JSON.

الاستعمال (PowerShell):
    $env:DATABASE_URL="postgresql://..."
    venv\\Scripts\\python.exe backup_online.py
"""
import io
import json
import os
import sys
from datetime import datetime

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

# يقرأ من متغير البيئة أو من ملف .env المحلي (غير منشور على GitHub)
if not os.environ.get("DATABASE_URL"):
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if os.path.exists(env_path):
        with open(env_path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("DATABASE_URL="):
                    os.environ["DATABASE_URL"] = line.split("=", 1)[1].strip().strip('"').strip("'")
                    break
if not os.environ.get("DATABASE_URL"):
    print("ERREUR: حدد متغير DATABASE_URL أولاً!")
    sys.exit(1)

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)
backup = {
    "date": datetime.now().isoformat(timespec="seconds"),
    "users": client.get("/users").json(),
    "equipments": client.get("/equipments").json(),
    "transports": client.get("/transports").json(),
    "events": client.get("/events").json(),
    "app_events": client.get("/app-events").json(),
}

# إخفاء كلمات السر من النسخة (نحتفظ بالبنية فقط)
for u in backup["users"]:
    u.pop("password_hash", None)

os.makedirs("backups", exist_ok=True)
path = f"backups/backup_{datetime.now().strftime('%Y-%m-%d_%H-%M')}.json"
with open(path, "w", encoding="utf-8") as f:
    json.dump(backup, f, ensure_ascii=False, indent=2)

print(f"OK -> {path}")
print(f"users={len(backup['users'])} equipments={len(backup['equipments'])} "
      f"transports={len(backup['transports'])} app_events={len(backup['app_events'])}")
