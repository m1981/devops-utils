FROM ubuntu:22.04

# Arguments for UID and GID that we'll pass during build
ARG USER_ID
ARG GROUP_ID

# Install required packages
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    wget \
    age \
    && rm -rf /var/lib/apt/lists/*

# Install SOPS
RUN wget -O /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64 && \
    chmod +x /usr/local/bin/sops

# Create group and user matching host's UID/GID
RUN groupadd -g "${GROUP_ID}" developer || true && \
    useradd -u "${USER_ID}" -g "${GROUP_ID}" -m -s /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Create .sops directory for age keys
RUN mkdir -p /home/developer/.sops && \
    chown -R "${USER_ID}:${GROUP_ID}" /home/developer/.sops && \
    chmod 700 /home/developer/.sops

# Switch to the developer user
USER developer
WORKDIR /home/developer

# Set required environment variables
ENV HOME=/home/developer \
    USER=developer

CMD ["/bin/bash"]
