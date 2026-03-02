# ---------- Stage 1 : build ----------
FROM python:3.12-slim AS builder

WORKDIR /app

# Installe les dépendances système nécessaires à la compilation
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copie uniquement la config pour profiter du cache Docker
COPY pyproject.toml .

# Installe les dépendances runtime (sans [dev])
RUN pip install --no-cache-dir --prefix=/install .

# ---------- Stage 2 : runtime ----------
FROM python:3.12-slim

WORKDIR /app

# Dépendances runtime minimales (libpq pour psycopg2, libgl pour opencv)
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 libgl1 libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/*

# Récupère les paquets Python installés au stage builder
COPY --from=builder /install /usr/local

# Copie le code source
COPY . .

# Pas de venv/requirements.txt dans l'image
RUN rm -rf venv requirements.txt

CMD ["python", "consumer.py"]
