# rocky8-python
Rocky Linux 8 with Python built from source code.

Built image available in GitHub container registry:
```
docker pull ghcr.io/jurajama/rocky8-python:latest
```

The image is published as a multi-platform image for `linux/amd64` and `linux/arm64`, so the same tag
works on both architectures and Docker pulls the matching image automatically.

## Automated builds

The [build workflow](.github/workflows/build.yml) builds both platforms in parallel on native GitHub runners
(`ubuntu-24.04` for amd64, `ubuntu-24.04-arm` for arm64) and then combines them into a single multi-platform
manifest list. Tags are assigned as follows:

| Trigger                     | Tag      |
|-----------------------------|----------|
| Push to `main`              | `latest` |
| Push to any other branch    | `dev`    |
| Git tag `vX.Y.Z`            | `X.Y.Z`  |

## Building manually

Build both platforms and push them as a multi-platform image in one step with Docker Buildx.
The platform that doesn't match your machine is built under QEMU emulation, which is considerably slower.
```
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t <username>/rocky8-python:latest --push .
```

Check that both platforms are included:
```
docker buildx imagetools inspect <username>/rocky8-python:latest
```

To build only for the local platform and load the image into the local Docker image store:
```
docker buildx build --load -t rocky8-python .
```
