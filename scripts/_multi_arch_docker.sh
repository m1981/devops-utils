#!/usr/bin/env bash
set -e

# Detect OS and Architecture
case "$(uname -s)" in
    Darwin*)
        echo "🍎 macOS detected"
        export DOCKER_UID=$(id -u)
        export DOCKER_GID=$(id -g)
        export CONSISTENCY="cached"

        # Detect Mac architecture
        if [ "$(uname -m)" = "arm64" ]; then
            echo "📱 Apple Silicon (M1/M2) detected"
            export DOCKER_PLATFORM="linux/arm64"
            export DOCKER_ARCH="arm64"
            export TARGETARCH="arm64"
        else
            echo "💻 Intel Mac detected"
            export DOCKER_PLATFORM="linux/amd64"
            export DOCKER_ARCH="amd64"
            export TARGETARCH="amd64"
        fi
        ;;
    Linux*)
        echo "🐧 Linux detected"
        export DOCKER_UID=$(id -u)
        export DOCKER_GID=$(id -g)
        export CONSISTENCY="default"

        # Detect Linux architecture
        if [ "$(uname -m)" = "aarch64" ]; then
            echo "📱 ARM64 architecture detected"
            export DOCKER_PLATFORM="linux/arm64"
            export DOCKER_ARCH="arm64"
            export TARGETARCH="arm64"
        else
            echo "💻 AMD64 architecture detected"
            export DOCKER_PLATFORM="linux/amd64"
            export DOCKER_ARCH="amd64"
            export TARGETARCH="amd64"
        fi
        ;;
    *)
        echo "⚠️  Unknown operating system"
        exit 1
        ;;
esac

# Create fake_home directory if it doesn't exist
FAKE_HOME_DIR=${FAKE_HOME_DIR:-~/fake_home}
mkdir -p "$FAKE_HOME_DIR"

# Build the image if needed
docker compose build shell

# Export common environment variables
export WORKSPACE=${WORKSPACE:-./}
export FAKE_HOME_DIR

# Print setup information
echo "🔧 Setup Configuration:"
echo "User ID: $DOCKER_UID"
echo "Group ID: $DOCKER_GID"
echo "Workspace Directory: $WORKSPACE"
echo "Fake Home Directory: $FAKE_HOME_DIR"
echo "Volume Consistency: $CONSISTENCY"
echo "Docker Platform: $DOCKER_PLATFORM"
echo "Architecture: $DOCKER_ARCH"

# Run the container
echo "🚀 Starting shell..."
docker compose run --remove-orphans --rm shell
