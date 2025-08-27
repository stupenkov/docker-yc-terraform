FROM alpine:3.22

# Install essential utilities
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    git \
    openssh-client \
    gnupg \
    unzip

# Install Yandex Cloud CLI (yc) - corrected version
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | \
    bash -s -- -a && \
    mv /root/yandex-cloud/bin/yc /usr/local/bin/ && \
    rm -rf /root/yandex-cloud && \
    yc version

# Install Terraform
ENV TERRAFORM_VERSION=1.13.0
ENV TERRAFORM_MIRROR=https://hashicorp-releases.yandexcloud.net/terraform

RUN curl -LO ${TERRAFORM_MIRROR}/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && chmod +x /usr/local/bin/terraform \
    && terraform version

# Create working directory
WORKDIR /app

# Copy scripts
COPY scripts/ /usr/local/bin/

# Set permissions
RUN chmod +x /usr/local/bin/*.sh && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Create default Terraform configuration
RUN mkdir -p /app/defaults
COPY --chmod=644 defaults/main.tf /app/defaults/
COPY --chmod=644 defaults/variables.tf /app/defaults/

# Set default environment variables
ENV YC_TOKEN=""
ENV YC_CLOUD_ID=""
ENV YC_FOLDER_ID=""
ENV YC_ZONE="ru-central1-a"

# Entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
