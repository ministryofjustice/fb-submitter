UID ?= $(shell id -u)
DOCKER_COMPOSE = env UID=$(UID) docker-compose -f docker-compose.yml -f docker-compose.development.yml

dev:
	echo "TODO: Remove dev function call from deploy-utils"

test:
	echo "TODO: Remove test function call from deploy-utils"

integration:
	echo "TODO: Remove integration function call from deploy-utils"

live:
	echo "TODO: Remove live function call from deploy-utils"

build: stop
	$(DOCKER_COMPOSE) build --build-arg BUNDLE_FLAGS=''

serve: build
	$(DOCKER_COMPOSE) up -d db
	./scripts/wait_for_db.sh db postgres
	$(DOCKER_COMPOSE) up -d app
	$(DOCKER_COMPOSE) up -d worker

stop:
	$(DOCKER_COMPOSE) down -v

spec: build
	$(DOCKER_COMPOSE) up -d db
	./scripts/wait_for_db.sh db postgres
	$(DOCKER_COMPOSE) run --rm app bundle exec rspec

.PHONY: shell
shell: stop build
	$(DOCKER_COMPOSE) up -d app
	$(DOCKER_COMPOSE) exec app bash

.PHONY: init
init:
	$(eval export ECR_REPO_NAME_SUFFIXES=base web api)
	$(eval export ECR_REPO_URL_ROOT=754256621582.dkr.ecr.eu-west-2.amazonaws.com/formbuilder)

# install aws cli w/o sudo
install_build_dependencies: init
	docker --version
	pip install --user awscli
	$(eval export PATH=${PATH}:${HOME}/.local/bin/)

build_and_push: install_build_dependencies
	REPO_SCOPE=${ECR_REPO_URL_ROOT} CIRCLE_SHA1=${CIRCLE_SHA1} ./scripts/build_and_push_all.sh

.PHONY := init push build spec test integration live serve install_build_dependencies
