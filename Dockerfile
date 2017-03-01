FROM madharjan/docker-base:14.04
MAINTAINER Madhav Raj Maharjan <madhav.maharjan@gmail.com>

ARG VCS_REF
ARG SQUID_VERSION
ARG DEBUG=false

LABEL description="Docker container for Squid" os_version="Ubuntu ${UBUNTU_VERSION}" \
      org.label-schema.vcs-ref=${VCS_REF} org.label-schema.vcs-url="https://github.com/madharjan/docker-squid"

ENV SQUID_VERSION ${SQUID_VERSION}

RUN mkdir -p /build
COPY . /build

RUN /build/scripts/install.sh && /build/scripts/cleanup.sh

VOLUME ["/var/cache/squid3/", "/var/log/squid3"]

CMD ["/sbin/my_init"]

EXPOSE 3128 3129
