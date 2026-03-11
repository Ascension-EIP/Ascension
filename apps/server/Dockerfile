# ── Build stage ───────────────────────────────────────────────────────────────
FROM rust:1.91.1-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
	perl \
	make \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cache dependencies layer
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo 'fn main() {}' > src/main.rs \
	&& cargo build --release \
	&& rm -rf src

# Copy sqlx offline query cache, migrations and sources
COPY .sqlx ./.sqlx
COPY migrations ./migrations
COPY src ./src
ENV SQLX_OFFLINE=true
RUN touch src/main.rs && cargo build --release

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM debian:trixie-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/server ./server
COPY migrations ./migrations

EXPOSE 8080

CMD ["./server"]
