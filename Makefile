dev:
	echo "TODO: Remove dev function call from deploy-utils"

test:
	echo "TODO: Remove test function call from deploy-utils"

integration:
	echo "TODO: Remove integration function call from deploy-utils"

live:
	echo "TODO: Remove live function call from deploy-utils"

build: stop
	docker-compose build --build-arg BUNDLE_FLAGS=''

serve: build
	docker-compose up -d redis
	docker-compose up -d db
	./scripts/wait_for_db.sh db postgres
	docker-compose up -d app
	docker-compose up -d worker

stop:
	docker-compose down -v

spec: build
	docker-compose up -d db
	./scripts/wait_for_db.sh db postgres
	docker-compose run --rm app bundle exec rspec

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
