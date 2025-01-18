#!/bin/bash
set -eu

echo "Building all utility containers..."
# Get host user's UID and GID
HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Build the image
docker build \
  --build-arg USER_ID=$HOST_UID \
  --build-arg GROUP_ID=$HOST_GID \
  -t age-dev docker/age-sops

## Test the setup
#docker run -it --rm \
#  -v $(pwd):/home/developer/work \
#  age-dev bash -ce '
#    /usr/local/bin/check-age-environment.sh
#  '

#todo: Add Terraform build and test
#docker build -t terraform-workspace docker/terraform