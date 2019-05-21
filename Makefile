
NAME = madharjan/docker-squid
VERSION = 3.5.12

DEBUG ?= true

DOCKER_USERNAME ?= $(shell read -p "DockerHub Username: " pwd; echo $$pwd)
DOCKER_PASSWORD ?= $(shell stty -echo; read -p "DockerHub Password: " pwd; stty echo; echo $$pwd)
DOCKER_LOGIN ?= $(shell cat ~/.docker/config.json | grep "docker.io" | wc -l)

.PHONY: all build run test stop clean tag_latest release clean_images

all: build

docker_login:
ifeq ($(DOCKER_LOGIN), 1)
		@echo "Already login to DockerHub"
else
		@docker login -u $(DOCKER_USERNAME) -p $(DOCKER_PASSWORD)
endif

build:
	docker build \
	 --build-arg SQUID_VERSION=${VERSION} \
	 --build-arg VCS_REF=`git rev-parse --short HEAD` \
	 --build-arg DEBUG=$(DEBUG) \
	 -t $(NAME):$(VERSION) --rm .

run:
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi

	rm -rf /tmp/squid
	mkdir -p /tmp/squid/cache

	docker run -d \
		-e DEBUG=$(DEBUG) \
		--name squid_default $(NAME):$(VERSION)

	sleep 2

	docker run -d \
		--link squid_default:proxy \
		-e DEBUG=$(DEBUG) \
		-e SQUID_CACHE_PEER_HOST=proxy \
		-e SQUID_CACHE_PEER_PORT=3128 \
		-v /tmp/squid/cache:/var/cache/squid \
		--name squid $(NAME):$(VERSION)

	sleep 2

	docker run -d \
		-e DEBUG=$(DEBUG) \
		-e DISABLE_SQUID=1 \
		--name squid_no_squid $(NAME):$(VERSION)

	sleep 2


run_t:
	rm -rf /tmp/squid
	mkdir -p /tmp/squid/cache

	docker run -d \
		-e DEBUG=$(DEBUG) \
		--network=host \
		--cap-add=NET_ADMIN \
		-e SQUID_HTTP_PORT=9090 \
		-e SQUID_INTERCEPT_PORT=9091 \
		-e ENABLE_TRANSPARENT_PROXY=1 \
		-v /tmp/squid/cache:/var/cache/squid \
		--name squid_t $(NAME):$(VERSION)

	sleep 2

test:
	sleep 2
	./bats/bin/bats test/tests.bats

stop:
	docker exec squid /bin/bash -c "sv stop squid" 2> /dev/null || true
	sleep 2
	docker exec squid /bin/bash -c "rm -rf /var/cache/squid/*" 2> /dev/null || true
	docker stop squid squid_default squid_no_squid 2> /dev/null || true

clean:stop
	docker rm squid squid_default squid_no_squid 2> /dev/null || true
	rm -rf /tmp/squid || true
	docker images | grep "<none>" | awk '{print$3 }' | xargs docker rmi 2> /dev/null || true

stop_t:
	docker exec squid_t /bin/bash -c "sv stop squid" 2> /dev/null || true
	sleep 2
	docker exec squid_t /bin/bash -c "rm -rf /var/cache/squid/*" 2> /dev/null || true
	docker stop squid_t  2> /dev/null|| true

clean_t:stop_t
	docker rm squid_t  2> /dev/null|| true
	rm -rf /tmp/squid || true

publish: docker_login run test clean
	docker push $(NAME)

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: docker_login  run test clean tag_latest
	docker push $(NAME)

clean_images: clean
	docker rmi $(NAME):latest $(NAME):$(VERSION) 2> /dev/null || true
	docker logout 


