---
title: Sono Sghaier API
emoji: 🎛️
colorFrom: yellow
colorTo: black
sdk: docker
app_port: 7860
pinned: false
---

# SONO SGHAIER — Backend API

API de gestion événementielle (FastAPI + SQLAlchemy) pour l'application mobile **Sono Sghaier**.

## Lancement local

```bash
venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000
```

## Déploiement (Hugging Face Spaces — Docker)

Ce dépôt se déploie tel quel : le `Dockerfile` lance l'API sur le port `7860`.
Optionnel : définir la variable d'environnement `DATABASE_URL` (Postgres) pour
une base persistante, sinon SQLite local est utilisé.
