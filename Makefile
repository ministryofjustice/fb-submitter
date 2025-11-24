UID ?= $(shell id -u)
DOCKER_COMPOSE = env UID=$(UID) docker-compose -f docker-compose.yml -f docker-compose.development.yml

.PHONY: build
build: stop
	$(DOCKER_COMPOSE) build

.PHONY: serve
serve: build
	$(DOCKER_COMPOSE) up app

.PHONY: setup
setup: build
	$(DOCKER_COMPOSE) build --parallel
	$(DOCKER_COMPOSE) up -d

.PHONY: stop
stop:
	$(DOCKER_COMPOSE) down -v

.PHONY: build
spec: build
	$(DOCKER_COMPOSE) run --rm submitter-api env RAILS_ENV=test bundle exec rspec

.PHONY: unit
unit:
	$(DOCKER_COMPOSE) run --rm submitter-api env RAILS_ENV=test bundle exec rspec spec/controllers/concerns/error_handling_spec.rb

.PHONY: shell
shell: stop build
	$(DOCKER_COMPOSE) up -d submitter-api
	$(DOCKER_COMPOSE) exec submitter-api bash

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
