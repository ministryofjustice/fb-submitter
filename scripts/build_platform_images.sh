#!/usr/bin/env sh

node_modules/\@ministryofjustice/fb-deploy-utils/bin/build_platform_images.sh $@ --app fb-submitter --images api --images worker
