# rocky8-python
Rocky Linux 8 with Python built from source code.

Available in Dockerhub https://hub.docker.com/r/jurajama/rocky8-python


# Build commands for different architectures:

## AMD64
```
docker build -t <username>/rocky8-python:amd64 --build-arg ARCH=amd64/ .
docker push <username>/rocky8-python:amd64
```

## ARM64
```
docker build -t <username>/rocky8-python:arm64v8 --build-arg ARCH=arm64v8/ .
docker push <username>/rocky8-python:arm64v8
```

## Create manifest
```
docker manifest create \
<username>/rocky8-python:latest \
--amend <username>/rocky8-python:amd64 \
--amend <username>/rocky8-python:arm64v8
```

Push manifest:
```
docker manifest push <username>/rocky8-python:latest
```
