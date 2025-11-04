# Dockerfile for testing claude-docker in a Docker-in-Docker environment
# This creates a test environment that can run Docker commands to test the full setup

FROM docker:24-dind

# Install required dependencies for claude-docker
RUN apk add --no-cache \
    bash \
    git \
    curl \
    nodejs \
    npm \
    zsh \
    sudo \
    openssh-client \
    ca-certificates

# Create a test user with sudo privileges
RUN addgroup -g 1000 testuser && \
    adduser -D -u 1000 -G testuser -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Configure git (required for claude-docker)
RUN git config --global user.name "Test User" && \
    git config --global user.email "test@example.com"

# Install Claude Code (required for claude-docker)
USER root
RUN npm install -g @anthropic-ai/claude-code

# Create zshrc for testuser
USER testuser
RUN touch /home/testuser/.zshrc && \
    touch /home/testuser/.bashrc

# Copy the test script
COPY test-setup.sh /home/testuser/test-setup.sh
RUN sudo chmod +x /home/testuser/test-setup.sh

USER root
# Entrypoint that starts Docker daemon and runs tests
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
