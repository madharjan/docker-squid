# docker-squid

[![](https://images.microbadger.com/badges/image/madharjan/docker-squid.svg)](https://microbadger.com/images/madharjan/docker-squid "Get your own image badge on microbadger.com")

Docker container for Squid Proxy based on [madharjan/docker-base](https://github.com/madharjan/docker-base/)

Squid configuration and Transparent Proxy configuration based on [jpetazzo/squid-in-a-can](https://github.com/jpetazzo/squid-in-a-can)

**Changes**
* Squid and iptables in single container
* Install `iptables` config if run as Transparent Proxy and cleanup `iptables` config on container stop

**Features**
* Environment variables to set upstream proxy & authentication
* Environment variables to set cache settings
* Bats ([sstephenson/bats](https://github.com/sstephenson/bats/)) based test cases

**Usages**
* Run `docker-squid` as Transparent Proxy while `docker build` to speedup build time by caching  OS packages downloads
* Run `docker-squid` as Transparent Proxy while `docker build` behind Corporate Proxy WITHOUT changing Dockerfile *(works only if all downloads from Internet is HTTP only, NOT HTTPS)*
* Run `docker-squid` to conserve bandwidth on slow Internet connection by caching frequently downloaded files


## Squid 3.3.8 (docker-squid)

**Environment**

| Variable                  | Default | Example        |
|---------------------------|---------|----------------|
| DISABLE_SQUID             | 0       | 1 (to disable) |
| SQUID_INTERFACE_IP        | 0.0.0.0 | 170.17.42.1    |
| SQUID_HTTP_PORT           | 3128    | 8080           |
| SQUID_INTERCEPT_PORT      | 3129    | 8081           |
| SQUID_MAXIMUM_OBJECT_SIZE | 1024    | 512  (MB)      |
| SQUID_DISK_CACHE_SIZE     | 10000   | 1000           |
| SQUID_CACHE_PEER_HOST     |         | proxyHost      |
| SQUID_CACHE_PEER_PORT     |         | proxyPort      |
| SQUID_CACHE_PEER_AUTH     |         | user:pass      |
| ENABLE_TRANSPARENT_PROXY  | 0       | 1 (to enable)  |


## Build

**Clone this project**
```
git clone https://github.com/madharjan/docker-squid
cd docker-squid
```

**Build Container**
```
# login to DockerHub
docker login

# build
make

# tests
make run
make tests
make clean

# tag
make tag_latest

# update Changelog.md
# release
make release
```

**Tag and Commit to Git**
```
git tag 3.3.8
git push origin 3.3.8
```

## Run Container

### Squid

**Prepare folder on host for container volumes**
```
sudo mkdir -p /opt/docker/squid/cache/
sudo mkdir -p /opt/docker/squid/log/
```

**Run `docker-squid`**
```
docker stop squid
docker rm squid

docker run -d \
  -p 8080:3128 \
  -e SQUID_CACHE_PEER_HOST=proxyHost \
  -e SQUID_CACHE_PEER_PORT=proxyPort \  
  -v /opt/docker/squid/cache:/var/cache/squid3 \
  -v /opt/docker/squid/log:/var/log/squid3 \
  --name squid \
  madharjan/docker-squid:3.3.8
```

**Run as Transparent Proxy**
```
docker stop squid
docker rm squid

docker run -d \
  --network=host \
  --cap-add=NET_ADMIN \
  -e SQUID_HTTP_PORT=9090 \
  -e SQUID_INTERCEPT_PORT=9091 \
  -e SQUID_CACHE_PEER_HOST=proxyHost \
  -e SQUID_CACHE_PEER_PORT=proxyPort \  
  -e ENABLE_TRANSPARENT_PROXY=1 \
  -v /opt/docker/squid/cache:/var/cache/squid3 \
  -v /opt/docker/squid/log:/var/log/squid3 \
  --name squid \
  madharjan/docker-squid:3.3.8
```

**Systemd Unit File**
```
[Unit]
Description=Squid

After=docker.service

[Service]
TimeoutStartSec=0

ExecStartPre=-/bin/mkdir -p /opt/docker/squid/cache
ExecStartPre=-/bin/mkdir -p /opt/docker/squid/log
ExecStartPre=-/usr/bin/docker stop squid
ExecStartPre=-/usr/bin/docker rm squid
ExecStartPre=-/usr/bin/docker pull madharjan/docker-squid:3.3.8

ExecStart=/usr/bin/docker run \
  -p 8080:3128 \
  -v /opt/docker/squid/cache:/var/cache/squid3 \
  -v /opt/docker/squid/log:/var/log/squid3 \
  --name squid \
  madharjan/docker-squid:3.3.8

ExecStop=/usr/bin/docker stop -t 2 squid

[Install]
WantedBy=multi-user.target
```
