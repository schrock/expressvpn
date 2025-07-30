#! /bin/bash

# ExpressVPN client version
NUM="3.83.0.2"

echo "### [BUILDING IMAGE] ###"
podman buildx build --build-arg NUM=$NUM --build-arg DISTRIBUTION=bookworm --build-arg PLATFORM=amd64 --platform linux/amd64 -t schrock/expressvpn:latest .

echo "### [CLEANUP] ###"
podman image prune -f
