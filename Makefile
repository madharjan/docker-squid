
NAME = madharjan/docker-squid
VERSION = 3.3.8

.PHONY: all build run tests clean tag_latest release clean_images

all: build

build:
	docker build \
	 --build-arg SQUID_VERSION=${VERSION} \
	 --build-arg VCS_REF=`git rev-parse --short HEAD` \
	 --build-arg DEBUG=true \
	 -t $(NAME):$(VERSION) --rm .

run:
	rm -rf /tmp/squid
	mkdir -p /tmp/squid/cache

	docker run -d \
		-e DEBUG=true \
		--name squid_default $(NAME):$(VERSION)

	sleep 2

	docker run -d \
		--link squid_default:proxy \
		-e DEBUG=true \
		-e SQUID_CACHE_PEER_HOST=proxy \
		-e SQUID_CACHE_PEER_PORT=3128 \
		-v /tmp/squid/cache:/var/cache/squid3 \
		--name squid $(NAME):$(VERSION)

	sleep 2

	docker run -d \
		-e DEBUG=true \
		-e DISABLE_SQUID=1 \
		--name squid_no_squid $(NAME):$(VERSION)

	sleep 2

tests:
	sleep 2
	./bats/bin/bats test/tests.bats

clean:
	docker exec squid /bin/bash -c "sv stop squid" || true
	sleep 2
	docker exec squid /bin/bash -c "rm -rf /var/cache/squid3/*" || true
	docker stop squid squid_default squid_no_squid || true
	docker rm squid squid_default squid_no_squid || true
	rm -rf /tmp/squid || true

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: run tests clean tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! head -n 1 Changelog.md | grep -q 'release date'; then echo 'Please note the release date in Changelog.md.' && false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag $(VERSION) && git push origin $(VERSION) ***"

	curl -X POST https://hooks.microbadger.com/images/madharjan/docker-squid/Y7V64vqIP3mXfQarb7lAU8uE2XU=

clean_images:
	docker rmi $(NAME):latest $(NAME):$(VERSION) || true
