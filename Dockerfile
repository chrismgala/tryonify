FROM ruby:3.1.2-alpine

ARG SHOPIFY_API_KEY
ARG HOST
ARG THEME_EXTENSION_ID
ARG RAILS_MASTER_KEY
ENV SHOPIFY_API_KEY=$SHOPIFY_API_KEY
ENV HOST=$HOST
ENV THEME_EXTENSION_ID=$THEME_EXTENSION_ID

RUN apk update && apk add nodejs npm git build-base sqlite-dev gcompat bash libpq-dev
WORKDIR /app

COPY web .

RUN cd frontend && npm install
RUN bundle install

RUN cd frontend && npm run build
RUN rake build:all

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]