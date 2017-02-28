#!/bin/bash

set -e

if [ "${DEBUG}" == true ]; then
  set -x
fi

DISABLE_SQUID=${DISABLE_SQUID:-0}

if [ ! "${DISABLE_SQUID}" -eq 0 ]; then
  touch /etc/service/squid/down
else
  rm -f /etc/service/squid/down
fi

sed -i "s/^#acl localnet/acl localnet/" /etc/squid3/squid.conf
sed -i "s/^#http_access allow localnet/http_access allow localnet/" /etc/squid3/squid.conf

sed -i "s/^#cache_dir .*/cache_dir ufs \/var\/cache\/squid3 10000 16 256/" /etc/squid3/squid.conf
sed -i "s/^# maximum_object_size .*/maximum_object_size 1024 MB/" /etc/squid3/squid.conf

echo "http_port 3129 intercept" >> /etc/squid3/squid.conf

mkdir -p /var/cache/squid3
chown -R proxy:proxy /var/cache/squid3

/usr/sbin/squid3 -z
