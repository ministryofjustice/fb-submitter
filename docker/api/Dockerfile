FROM ruby:2.6.3

RUN apt-get update && apt-get install -y postgresql-contrib libpq-dev

ENV RAILS_ROOT /var/www/fb-submitter
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY . $RAILS_ROOT
RUN gem install bundler
RUN bundle install --jobs 4 --retry 5 --deployment --without test development

RUN groupadd -r deploy && useradd -m -u 1001 -r -g deploy deploy
RUN chown -R deploy $RAILS_ROOT
USER 1001

# allow access to port 3000
ENV APP_PORT 3000
EXPOSE $APP_PORT

# run the rails server
ARG RAILS_ENV=production
CMD bundle exec rake db:migrate && bundle exec rails s -e ${RAILS_ENV} -p ${APP_PORT} --binding=0.0.0.0
