FROM alpine:3.22

# Install essential utilities with pinned versions
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    git \
    openssh-client \
    gnupg \
    unzip \
    && addgroup -g 1000 -S appgroup \
    && adduser -S appuser -u 1000 -G appgroup

# Install Yandex Cloud CLI (yc) - corrected version
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | \
    bash -s -- -a && \
    mv /root/yandex-cloud/bin/yc /usr/local/bin/ && \
    rm -rf /root/yandex-cloud && \
    yc version
SHELL ["/bin/sh", "-c"]

# Install Terraform with pinned versions
ENV TERRAFORM_VERSION=1.13.0
ENV TERRAFORM_MIRROR=https://hashicorp-releases.yandexcloud.net/terraform

RUN curl -LO ${TERRAFORM_MIRROR}/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
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
