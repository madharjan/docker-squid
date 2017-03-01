#!/bin/bash
set -e
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

if [ "${DEBUG}" = true ]; then
  set -x
fi

SQUID_BUILD_PATH=/build/services/squid

## Install Squid.
apt-get install -y --no-install-recommends squid

mkdir -p /etc/service/squid
cp ${SQUID_BUILD_PATH}/squid.runit /etc/service/squid/run
chmod 750 /etc/service/squid/run
