# fb-submitter
[![CircleCI](https://circleci.com/gh/ministryofjustice/fb-submitter/tree/master.svg?style=svg)](https://circleci.com/gh/ministryofjustice/fb-submitter/tree/master)
[![Build Status](https://travis-ci.org/ministryofjustice/fb-submitter.svg?branch=master)](https://travis-ci.org/ministryofjustice/fb-submitter)

API for services built &amp; deployed on Form Builder to send the user data to
where it ultimately needs to go.

## Environment Variables

The following environment variables are either needed, or read if present:

* DATABASE_URL: used to connect to the database
* FB_ENVIRONMENT_SLUG: what FormBuilder environment is this submitter for?
  Should be equal to one of the keys in config/service_environments.rb
* RAILS_ENV: 'development' or 'production'
* SERVICE_TOKEN_CACHE_ROOT_URL: protocol + hostname of the
  [service token cache](https://github.com/ministryofjustice/fb-service-token-cache)

## To deploy and run on Cloud Platforms

See [deployment instructions](DEPLOY.md)

## API documentation

See [Swagger documentation](https://ministryofjustice.github.io/fb-submitter)
