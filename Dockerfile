FROM golang:1.19-alpine
RUN apk add build-base

WORKDIR /app
ADD . /app
RUN go build -o /onboarding-lfell

FROM alpine:latest
COPY --from=0 /onboarding-lfell /
EXPOSE 8080
CMD ["/onboarding-lfell"]
