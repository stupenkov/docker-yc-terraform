FROM alpine:3.22

# Установка основных утилит
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    git \
    openssh-client \
    gnupg \
    unzip

# Установка Yandex Cloud CLI (yc) - исправленная версия
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | \
    bash -s -- -a && \
    mv /root/yandex-cloud/bin/yc /usr/local/bin/ && \
    rm -rf /root/yandex-cloud && \
    yc version

# Установка Terraform
ENV TERRAFORM_VERSION=1.13.0
ENV TERRAFORM_MIRROR=https://hashicorp-releases.yandexcloud.net/terraform

RUN curl -LO ${TERRAFORM_MIRROR}/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && chmod +x /usr/local/bin/terraform \
    && terraform version

# Создание рабочей директории
WORKDIR /app

# Копирование скриптов
COPY scripts/ /usr/local/bin/

# Настройка прав доступа
RUN chmod +x /usr/local/bin/*.sh && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Создание default конфигурации Terraform
RUN mkdir -p /app/defaults
COPY --chmod=644 defaults/main.tf /app/defaults/
COPY --chmod=644 defaults/variables.tf /app/defaults/

# Установка переменных окружения по умолчанию
ENV YC_TOKEN=""
ENV YC_CLOUD_ID=""
ENV YC_FOLDER_ID=""
ENV YC_ZONE="ru-central1-a"

# Точка входа
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]