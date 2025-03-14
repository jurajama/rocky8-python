# rocky8-python
Rocky Linux 8 with Python built from source code.

Built image available in GitHub container registry:
```
docker pull ghcr.io/jurajama/rocky8-python:latest
```

## Building manually

### AMD64
```
docker buildx build --platform linux/amd64 -t <username>/rocky8-python:amd64 .
docker push <username>/rocky8-python:amd64
```

### ARM64
```
docker buildx build --platform linux/arm64/v8 -t <username>/rocky8-python:arm64v8 .
docker push <username>/rocky8-python:arm64v8
```

### Create manifest
Manifest is needed to make multi-architecture image available via a single tag.
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
