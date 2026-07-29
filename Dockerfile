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

# bash for entrypoint; non-root user
RUN apk add --no-cache \
    bash=5.2.37-r0 \
    && addgroup -g 1000 -S appgroup \
    && adduser -S appuser -u 1000 -G appgroup

# Terraform CLI config (Yandex Cloud provider mirror)
COPY config/.terraformrc /etc/terraformrc
RUN chmod 644 /etc/terraformrc
ENV TF_CLI_CONFIG_FILE=/etc/terraformrc

WORKDIR /app
RUN chown -R appuser:appgroup /app

COPY scripts/ /home/appuser/
RUN chmod +x /home/appuser/*.sh

USER appuser
ENTRYPOINT ["/home/appuser/entrypoint.sh"]
