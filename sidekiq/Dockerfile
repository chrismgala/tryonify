FROM ruby:3.1-alpine

ARG RAILS_MASTER_KEY

RUN apk update && apk add nodejs npm git build-base sqlite-dev gcompat bash libpq-dev
WORKDIR /app

COPY web .

RUN bundle install
RUN bundle exec sidekiq -t 25 -q default -q mailers
