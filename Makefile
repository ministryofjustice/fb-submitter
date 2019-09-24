UID ?= $(shell id -u)
DOCKER_COMPOSE = env UID=$(UID) docker-compose -f docker-compose.yml -f docker-compose.development.yml

.PHONY: dev
dev:
	echo "TODO: Remove dev function call from deploy-utils"

.PHONY: test
test:
	echo "TODO: Remove test function call from deploy-utils"

.PHONY: integration
integration:
	echo "TODO: Remove integration function call from deploy-utils"

.PHONY: live
live:
	echo "TODO: Remove live function call from deploy-utils"

.PHONY: build
build: stop
	$(DOCKER_COMPOSE) build

.PHONY: serve
serve: build
	$(DOCKER_COMPOSE) up app

.PHONY: stop
stop:
	$(DOCKER_COMPOSE) down -v

.PHONY: build
spec: build
	$(DOCKER_COMPOSE) run --rm app bundle exec rspec

.PHONY: shell
shell: stop build
	$(DOCKER_COMPOSE) up -d app
	$(DOCKER_COMPOSE) exec app bash

.PHONY: init
init:
	$(eval export ECR_REPO_NAME_SUFFIXES=base web api)
	$(eval export ECR_REPO_URL_ROOT=754256621582.dkr.ecr.eu-west-2.amazonaws.com/formbuilder)

.PHONY: install_build_dependencies
# install aws cli w/o sudo
install_build_dependencies: init
	docker --version
	pip install --user awscli
	$(eval export PATH=${PATH}:${HOME}/.local/bin/)

.PHONY: build_and_push
build_and_push: install_build_dependencies
	REPO_SCOPE=${ECR_REPO_URL_ROOT} CIRCLE_SHA1=${CIRCLE_SHA1} ./scripts/build_and_push_all.sh
