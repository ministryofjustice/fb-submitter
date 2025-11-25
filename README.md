# fb-submitter

[![CircleCI](https://circleci.com/gh/ministryofjustice/fb-submitter/tree/main.svg?style=svg)](https://circleci.com/gh/ministryofjustice/fb-submitter/tree/main)

API for services built and deployed on Form Builder to send the user data to where it ultimately needs to go.

## Running the API

Docker is a prerequisite for running the api and required services

```sh
make setup
```

## Running tests

Docker is a prerequisite for running the tests

```sh
make spec
```

## Deployment

Continuous Integration (CI) is enabled on this project via CircleCI.

On merge to main tests are executed and if green deployed to the test environment.
This build can then be promoted to production


## Submission Payload Schema

`schemas/submission_payload.json` is the schema for the decrypted submission. The request object should take the form:

```
{
  encrypted_submission: 'WTq8zYcZfaWVvMncigHqwQ=='
}
```

Once decrypted the submission is validated against the schema before being re-encrypted and saved in the DB.
