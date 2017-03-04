#!/bin/bash

set -e

if [ "${DEBUG}" = true ]; then
  set -x
fi

DISABLE_SQUID=${DISABLE_SQUID:-0}
SQUID_INTERFACE_IP=${SQUID_INTERFACE_IP:-0.0.0.0}
SQUID_HTTP_PORT=${SQUID_HTTP_PORT:-3128}
SQUID_INTERCEPT_PORT=${SQUID_INTERCEPT_PORT:-3129}
SQUID_MAXIMUM_OBJECT_SIZE=${SQUID_MAXIMUM_OBJECT_SIZE:-1024}
SQUID_DISK_CACHE_SIZE=${SQUID_DISK_CACHE_SIZE:-10000}

SQUID_CACHE_PEER_HOST=${SQUID_CACHE_PEER_HOST:-}
SQUID_CACHE_PEER_PORT=${SQUID_CACHE_PEER_PORT:-}
SQUID_CACHE_PEER_AUTH=${SQUID_CACHE_PEER_AUTH:-}

ENABLE_TRANSPARENT_PROXY=${ENABLE_TRANSPARENT_PROXY:-0}

if [ ! "${DISABLE_SQUID}" -eq 0 ]; then
  touch /etc/service/squid/down
else
  rm -f /etc/service/squid/down
fi

sed -i "s/^#acl localnet/acl localnet/" /etc/squid3/squid.conf
sed -i "s/^#http_access allow localnet/http_access allow localnet/" /etc/squid3/squid.conf

sed -i "s/^#cache_dir .*/cache_dir ufs \/var\/cache\/squid3 ${SQUID_DISK_CACHE_SIZE} 16 256/" /etc/squid3/squid.conf
sed -i "s/^# maximum_object_size .*/maximum_object_size ${SQUID_MAXIMUM_OBJECT_SIZE} MB/" /etc/squid3/squid.conf

sed -i "s/^http_port .*/http_port ${SQUID_INTERFACE_IP}:${SQUID_HTTP_PORT}/" /etc/squid3/squid.conf

echo "http_port ${SQUID_INTERFACE_IP}:${SQUID_INTERCEPT_PORT} intercept" >> /etc/squid3/squid.conf

if [ ! x"${SQUID_CACHE_PEER_HOST}" = "x" ] && [ ! x"${SQUID_CACHE_PEER_PORT}" = "x" ]; then
  if [ ! x"${SQUID_CACHE_PEER_AUTH}" = "x" ]; then
    echo "cache_peer ${SQUID_CACHE_PEER_HOST} parent ${SQUID_CACHE_PEER_PORT} 0 proxy-only default no-query no-digest no-delay login=${SQUID_CACHE_PEER_AUTH}" >> /etc/squid3/squid.conf
    echo "never_direct allow all" >> /etc/squid3/squid.conf
  else
    echo "cache_peer ${SQUID_CACHE_PEER_HOST} parent ${SQUID_CACHE_PEER_PORT} 0 proxy-only default no-query no-digest no-delay" >> /etc/squid3/squid.conf
    echo "never_direct allow all" >> /etc/squid3/squid.conf
  fi
fi

cat <<EOT >> /etc/squid3/squid.conf

# refresh pattern for debs and udebs
refresh_pattern deb$         20160 100%   20160
refresh_pattern udeb$        20160 100%   20160
refresh_pattern tar.gz$      20160 100%   20160
refresh_pattern Release$      1440  40%   20160
refresh_pattern Sources.gz$   1440  40%   20160
refresh_pattern Packages.gz$  1440  40%   20160
refresh_pattern cvd$          1440  40%   20160
refresh_all_ims on
EOT

mkdir -p /var/cache/squid3
chown -R proxy:proxy /var/cache/squid3

/usr/sbin/squid3 -z

if [ "${ENABLE_TRANSPARENT_PROXY}" -eq 1 ]; then
  iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to ${SQUID_INTERCEPT_PORT} -w
  iptables -t nat -L -n -v
fi
