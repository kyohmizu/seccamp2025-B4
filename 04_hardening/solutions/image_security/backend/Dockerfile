FROM golang:1.23-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY main.go ./
RUN go build -o backend main.go

# イメージタグを変更
FROM alpine:3.22
WORKDIR /app
COPY --from=build /app/backend ./backend
EXPOSE 8000
CMD ["./backend"]
