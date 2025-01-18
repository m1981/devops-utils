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
    software-properties-common \
    lsb-release \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Install SOPS
RUN wget -O /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64 && \
    chmod +x /usr/local/bin/sops

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y terraform && \
    rm -rf /var/lib/apt/lists/*

# Install doctl directly (ARM64 compatible)
ENV DOCTL_VERSION="1.101.0"
RUN wget -O doctl.tar.gz "https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-arm64.tar.gz" && \
    tar xf doctl.tar.gz && \
    mv doctl /usr/local/bin && \
    chmod +x /usr/local/bin/doctl && \
    rm doctl.tar.gz

# Configure bash completion and prompt
RUN echo 'source /etc/bash_completion' >> /etc/bash.bashrc &&  \
    echo 'export PS1="\[\033[38;5;39m\]┌──(\[\033[38;5;82m\]terraform\[\033[38;5;39m\])-[\[\033[0;36m\]\w\[\033[38;5;39m\]]\n└─\[\033[38;5;82m\]$ \[\033[0m\]"' > /etc/profile.d/terraform-prompt.sh

# Add doctl bash completion
RUN doctl completion bash > /etc/bash_completion.d/doctl

# Create group and user matching host's UID/GID
RUN groupadd -g "${GROUP_ID}" developer || true && \
    useradd -u "${USER_ID}" -g "${GROUP_ID}" -m -s /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Create .sops directory for age keys
RUN mkdir -p /home/developer/.sops && \
    chown -R "${USER_ID}:${GROUP_ID}" /home/developer/.sops && \
    chmod 700 /home/developer/.sops

# Ensure custom prompt is sourced for developer user
RUN echo 'source /etc/profile.d/terraform-prompt.sh' >> /home/developer/.bashrc && \
    chown "${USER_ID}:${GROUP_ID}" /home/developer/.bashrc

# Switch to the developer user
USER developer
WORKDIR /home/developer

# Set required environment variables
ENV HOME=/home/developer \
    USER=developer

CMD ["/bin/bash -l"]
