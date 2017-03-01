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
cp /build/services/squid-startup.sh /etc/my_init.d
chmod 750 /etc/my_init.d/squid-startup.sh

mkdir -p /etc/my_shutdown.d
cp /build/services/iptables-remove.sh /etc/my_shutdown.d
chmod 750 /etc/my_shutdown.d/iptables-remove.sh
