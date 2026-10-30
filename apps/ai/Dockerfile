FROM python:3.11-slim

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		libgl1 \
		libglib2.0-0 \
		curl \
	&& rm -rf /var/lib/apt/lists/*

# Install dependencies via uv
COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen

COPY . .

ENTRYPOINT ["uv", "run", "worker"]
