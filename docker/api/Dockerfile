FROM ruby:2.6.4-alpine3.9

ARG UID=1001

RUN apk add build-base postgresql-contrib postgresql-dev bash libcurl

RUN addgroup -g ${UID} -S appgroup && \
  adduser -u ${UID} -S appuser -G appgroup

WORKDIR /app

COPY Gemfile* .ruby-version ./

ARG BUNDLE_FLAGS
RUN gem install bundler
RUN bundle install --no-cache ${BUNDLE_FLAGS}

COPY . .

ADD https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem ./rds-combined-ca-bundle.pem

RUN chown -R ${UID}:appgroup /app

USER UID

ENV APP_PORT 3000
EXPOSE $APP_PORT

ARG RAILS_ENV=production
CMD bundle exec rake db:migrate && bundle exec rails s -e ${RAILS_ENV} -p ${APP_PORT} --binding=0.0.0.0
