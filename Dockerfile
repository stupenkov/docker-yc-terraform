FROM alpine:3.22

# Install essential utilities with pinned versions
RUN apk add --no-cache \
    ca-certificates=20250619-r0 \
    curl=8.14.1-r1 \
    jq=1.8.0-r0 \
    bash=5.2.37-r0 \
    git=2.49.1-r0 \
    openssh-client=10.0_p1-r7 \
    gnupg=2.4.7-r0 \
    unzip=6.0-r15 \
    && addgroup -g 1000 -S appgroup \
    && adduser -S appuser -u 1000 -G appgroup

# Install Yandex Cloud CLI (yc)
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | \
    bash -s -- -a && \
    mv /root/yandex-cloud/bin/yc /usr/local/bin/ && \
    rm -rf /root/yandex-cloud && \
    yc version
SHELL ["/bin/sh", "-c"]

# Install Terraform with pinned version
ENV TERRAFORM_VERSION=1.13.0
RUN curl -fLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    chmod +x /usr/local/bin/terraform && \
    terraform version

# Create working directory and set permissions
WORKDIR /app
RUN chown -R appuser:appgroup /app

# Copy scripts and set permissions
COPY scripts/ /home/appuser/
RUN chmod +x /home/appuser/*.sh && \
    mkdir -p /home/appuser/.ssh && \
    chmod 700 /home/appuser/.ssh && \
    chown -R appuser:appgroup /home/appuser/.ssh

# Create default Terraform configuration
RUN mkdir -p /app/defaults && \
    chown -R appuser:appgroup /app/defaults
COPY --chmod=644 defaults/main.tf /app/defaults/
COPY --chmod=644 defaults/variables.tf /app/defaults/
RUN chown -R appuser:appgroup /app/defaults

# Set default environment variables
ENV YC_TOKEN=""
ENV YC_CLOUD_ID=""
ENV YC_FOLDER_ID=""
ENV YC_ZONE="ru-central1-a"

# Switch to non-root user
USER appuser

# Health check using local command instead of external service
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD yc --version || exit 1

# Entry point
ENTRYPOINT ["/home/appuser/entrypoint.sh"]
