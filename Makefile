
NAME = madharjan/docker-squid
VERSION = 3.5.12

DEBUG ?= true

.PHONY: all build run tests stop clean tag_latest release clean_images

all: build

build:
	docker build \
	 --build-arg SQUID_VERSION=${VERSION} \
	 --build-arg VCS_REF=`git rev-parse --short HEAD` \
	 --build-arg DEBUG=$(DEBUG) \
	 -t $(NAME):$(VERSION) --rm .

run:
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

tests:
	sleep 2
	./bats/bin/bats test/tests.bats

stop:
	docker exec squid /bin/bash -c "sv stop squid" || true
	sleep 2
	docker exec squid /bin/bash -c "rm -rf /var/cache/squid/*" || true
	docker stop squid squid_default squid_no_squid || true

clean:stop
	docker rm squid squid_default squid_no_squid || true
	rm -rf /tmp/squid || true
	docker images | grep "^<none>" | awk '{print$3 }' | xargs docker rmi || true

stop_t:
	docker exec squid_t /bin/bash -c "sv stop squid" || true
	sleep 2
	docker exec squid_t /bin/bash -c "rm -rf /var/cache/squid/*" || true
	docker stop squid_t || true

clean_t:stop_t
	docker rm squid_t || true
	rm -rf /tmp/squid || true

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: run tests clean tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag $(VERSION) && git push origin $(VERSION) ***"
	curl -s -X POST https://hooks.microbadger.com/images/$(NAME)/tURQR95JmBIZXtpNjAkk35k_tDc=

clean_images:
	docker rmi $(NAME):latest $(NAME):$(VERSION) || true
