#!/usr/bin/env sh
# exit as soon as any command fails
set -e

REPO_SCOPE=${REPO_SCOPE:-aldavidson}
TAG=${TAG:-latest}
AWS_ACCESS_KEY_ID_BASE=${AWS_ACCESS_KEY_ID_BASE:-${AWS_ACCESS_KEY_ID}}
AWS_SECRET_ACCESS_KEY_BASE=${AWS_SECRET_ACCESS_KEY_BASE:-${AWS_SECRET_ACCESS_KEY}}
AWS_ACCESS_KEY_ID_API=${AWS_ACCESS_KEY_ID_API:-${AWS_ACCESS_KEY_ID}}
AWS_SECRET_ACCESS_KEY_API=${AWS_SECRET_ACCESS_KEY_API:-${AWS_SECRET_ACCESS_KEY}}
AWS_ACCESS_KEY_ID_WORKER=${AWS_ACCESS_KEY_ID_WORKER:-${AWS_ACCESS_KEY_ID}}
AWS_SECRET_ACCESS_KEY_WORKER=${AWS_SECRET_ACCESS_KEY_WORKER:-${AWS_SECRET_ACCESS_KEY}}


concat_and_uppercase() {
  echo "$1_$2" | tr '[:lower:]' '[:upper:]'
}

for TYPE in api worker
do
  REPO_NAME=${REPO_SCOPE}/fb-submitter-${TYPE}
  KEY_VAR_NAME=$(concat_and_uppercase "AWS_ACCESS_KEY_ID" $TYPE)
  SECRET_VAR_NAME=$(concat_and_uppercase "AWS_SECRET_ACCESS_KEY" $TYPE)
  echo "Logging into ${REPO_SCOPE} with per-repo credentials ${KEY_VAR_NAME} ${SECRET_VAR_NAME}"
  AWS_ACCESS_KEY_ID=${!KEY_VAR_NAME}
  AWS_SECRET_ACCESS_KEY=${!SECRET_VAR_NAME}
  eval $(aws ecr get-login --no-include-email --region eu-west-2)
  echo "Pushing ${REPO_NAME}"
  docker push ${REPO_NAME}:${TAG}
  docker push ${REPO_NAME}:${CIRCLE_SHA1}
done
