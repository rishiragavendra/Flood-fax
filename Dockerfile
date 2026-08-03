# FloodFax AI — single-image build.
# Stage 1 builds the frontend to a static export; stage 2 serves the whole app
# (web UI + API + PDFs) from one FastAPI process on one port.

# --- Stage 1: build the web app ----------------------------------------------
FROM node:22-alpine AS web
WORKDIR /web
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci || npm install
COPY frontend/ ./
# Same-origin: no NEXT_PUBLIC_API_URL, so the client uses relative /api paths.
RUN npm run build   # emits /web/out

# --- Stage 2: python runtime that serves everything --------------------------
FROM python:3.12-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    FRONTEND_DIR=/srv/frontend

WORKDIR /srv

# matplotlib and reportlab need a couple of system libraries for font/image
# handling; curl is used by the healthcheck.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libfreetype6 libjpeg62-turbo curl \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install -r requirements.txt

COPY backend/app ./app
COPY --from=web /web/out ./frontend

RUN useradd --create-home --uid 10001 floodfax \
    && mkdir -p /srv/.data \
    && chown -R floodfax /srv
USER floodfax

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD curl -fsS http://localhost:8000/api/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
