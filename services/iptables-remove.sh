#!/bin/sh

. /etc/container_environment.sh

set -e

if [ "${DEBUG}" = true ]; then
  set -x
fi

SQUID_INTERCEPT_PORT=${SQUID_INTERCEPT_PORT:-3129}

iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to ${SQUID_INTERCEPT_PORT} -w
iptables -t nat -L -n -v
