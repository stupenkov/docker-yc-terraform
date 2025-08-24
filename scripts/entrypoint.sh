#!/bin/bash
set -e

# Проверка обязательных переменных
if [ -z "$YC_TOKEN" ]; then
    echo "Error: YC_TOKEN must be set"
    exit 1
fi

# Настройка yc config
if [ ! -z "$YC_CLOUD_ID" ] && [ ! -z "$YC_FOLDER_ID" ]; then
    yc config set token $YC_TOKEN
    yc config set cloud-id $YC_CLOUD_ID
    yc config set folder-id $YC_FOLDER_ID
    yc config set compute-default-zone $YC_ZONE
fi

# Копирование default файлов если директория app пуста
if [ ! "$(ls -A /app)" ]; then
    echo "Copying default Terraform configuration..."
    cp /app/defaults/*.tf /app/
fi

# Инициализация Terraform если есть конфигурационные файлы
if [ -f "/app/main.tf" ] || [ -f "/app/*.tf" ]; then
    echo "Initializing Terraform..."
    cd /app
    terraform init -input=false
fi

exec "$@"