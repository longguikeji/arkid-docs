.PHONY: \
	ci \
	lint test build \
	docker-dev docker-dev-build docker-dev-push \
	docker-prod docker-prod-build docker-prod-push

VERSION ?= 1.0.`date +%Y%m%d`
BASE_COMMIT_ID ?= ""

ci:
	docker build --build-arg base_commit_id="origin/master" \
	-t harbor.longguikeji.com/ark-releases/arkid-docs:$(VERSION) .

test:
	python manage.py migrate && python manage.py test siteapi.v1.tests

lint:
	@if [ ${BASE_COMMIT_ID}x != ""x ]; \
	then \
		git reset ${BASE_COMMIT_ID}; \
		git add .; \
	fi

	.git/hooks/pre-commit

build: docker-dev-build

docker-dev: docker-dev-build docker-dev-push

docker-dev-build:
	docker build -t harbor.longguikeji.com/ark-releases/arkid-docs:$(VERSION) .

docker-dev-push:
	docker push harbor.longguikeji.com/ark-releases/arkid-docs:$(VERSION)

docker-prod: docker-prod-build docker-prod-push

docker-prod-build:
	docker build -t  harbor.longguikeji.com/ark-releases/arkid-docs:$(VERSION) .

docker-prod-push:
	docker push harbor.longguikeji.com/ark-releases/arkid-docs:$(VERSION)

include custom.Makefile
