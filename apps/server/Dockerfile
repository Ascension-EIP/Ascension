FROM golang:1.25-alpine AS go-builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY pkg/ pkg/
COPY cmd/ cmd/
COPY internal/ internal/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
	go build \
	-ldflags="-s -w" \
	-o a.out \
	cmd/app/main.go


FROM alpine:3.20
WORKDIR /app

RUN addgroup -g 1000 bob && adduser -D -u 1000 -G bob bob

COPY db db
COPY --from=go-builder --chown=bob:bob /app/a.out ./a.out

USER bob

EXPOSE 8080

ENV GIN_MODE=release
ENTRYPOINT ["./a.out"]
