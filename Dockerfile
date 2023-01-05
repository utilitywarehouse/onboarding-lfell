FROM golang:1.17-alpine
RUN apk add build-base

WORKDIR /app
ADD . /app
RUN go build -o /onboarding-timestamp

FROM alpine:latest
COPY --from=0 /onboarding-timestamp /
EXPOSE 8080
CMD ["/onboarding-timestamp"]
