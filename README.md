# docker-squid
Docker container for Squid Proxy

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

# test
make test

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
