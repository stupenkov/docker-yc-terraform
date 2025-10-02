FROM hashicorp/terraform:1.13.0

# Labels for Docker Hub metadata
LABEL org.opencontainers.image.title="Yandex Cloud Terraform"
LABEL org.opencontainers.image.description="Docker container for Yandex Cloud infrastructure management with Terraform"
LABEL org.opencontainers.image.vendor="Stas Upenkov"
LABEL org.opencontainers.image.url="https://github.com/stupenkov/docker-yc-terraform"
LABEL org.opencontainers.image.source="https://github.com/stupenkov/docker-yc-terraform"
LABEL org.opencontainers.image.documentation="https://github.com/stupenkov/docker-yc-terraform/blob/main/README.md"
LABEL org.opencontainers.image.version="1.13.0"
LABEL org.opencontainers.image.licenses="MIT"

# Install essential utilities with pinned versions
RUN apk add --no-cache \
    curl=8.14.1-r2 \
    bash=5.2.37-r0 \
    && addgroup -g 1000 -S appgroup \
    && adduser -S appuser -u 1000 -G appgroup

# Install Yandex Cloud CLI (yc)
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | \
    bash -s -- -a && \
    mv /root/yandex-cloud/bin/yc /usr/local/bin/ && \
    rm -rf /root/yandex-cloud && \
    yc version

# Add terraform config file
COPY config/.terraformrc /etc/terraformrc
RUN chmod 644 /etc/terraformrc
ENV TF_CLI_CONFIG_FILE=/etc/terraformrc

# # Create working directory and set permissions
WORKDIR /app
RUN chown -R appuser:appgroup /app

# Copy scripts and set permissions
COPY scripts/ /home/appuser/
RUN chmod +x /home/appuser/*.sh && \
    mkdir -p /home/appuser/.ssh && \
    chmod 700 /home/appuser/.ssh && \
    chown -R appuser:appgroup /home/appuser/.ssh

# Switch to non-root user
USER appuser
ENTRYPOINT ["/home/appuser/entrypoint.sh"]
