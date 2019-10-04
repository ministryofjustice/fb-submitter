FROM ruby:2.6.4-alpine3.9

ARG UID=1001

RUN apk add build-base postgresql-contrib postgresql-dev bash libcurl

RUN addgroup -g ${UID} -S appgroup && \
  adduser -u ${UID} -S appuser -G appgroup

WORKDIR /app

RUN chown appuser:appgroup /app

COPY --chown=appuser:appgroup Gemfile Gemfile.lock .ruby-version ./

RUN gem install bundler

ARG BUNDLE_ARGS='--without test development'
RUN bundle install --no-cache ${BUNDLE_ARGS}

COPY --chown=appuser:appgroup . .

ADD https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem ./rds-combined-ca-bundle.pem

ENV APP_PORT 3000
EXPOSE $APP_PORT

ARG RAILS_ENV=production
CMD bundle exec rake db:migrate && bundle exec rails s -e ${RAILS_ENV} -p ${APP_PORT} --binding=0.0.0.0
