# Стадия сборки
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Устанавливаем зависимости для сборки если нужны
RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Собираем с оптимизациями и удалением отладочной информации
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -a \
    -ldflags='-w -s -extldflags "-static"' \
    -installsuffix cgo \
    -o main main.go

# Финальная стадия - пустой образ
FROM scratch

WORKDIR /app

# Копируем только бинарник
COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]