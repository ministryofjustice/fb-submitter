#!/usr/bin/env sh
# exit as soon as any command fails
set -e

REPO_SCOPE=${REPO_SCOPE:-aldavidson}
TAG=${TAG:-latest}

for TYPE in api worker
do
  REPO_NAME=${REPO_SCOPE}/fb-submitter-${TYPE}
  echo "Building ${REPO_NAME}"
  docker build -f docker/${TYPE}/Dockerfile -t ${REPO_NAME}:${TAG} -t ${REPO_NAME}:${CIRCLE_SHA1} .
done
