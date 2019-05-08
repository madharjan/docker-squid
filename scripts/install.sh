#!/bin/bash
set -e
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

if [ "${DEBUG}" = true ]; then
  set -x
fi

SQUID_CONFIG_PATH=/build/config/squid

apt-get update

## Install Squid and runit service
/build/services/squid/squid.sh

## Install iptables
apt-get install -y --no-install-recommends iptables

mkdir -p /etc/my_init.d
cp /build/services/12-squid.sh /etc/my_init.d
chmod 750 /etc/my_init.d/12-squid.sh

mkdir -p /etc/my_shutdown.d
cp /build/services/88-iptables.sh /etc/my_shutdown.d
chmod 750 /etc/my_shutdown.d/88-iptables.sh
