#!/bin/bash
set -euo pipefail

# Проверка обязательного аргумента - тега образа
if [[ $# -ne 1 ]]; then
    echo "❌ Usage: $0 <image-tag>"
    exit 1
fi

IMAGE_TAG="$1"

echo "🔍 Starting version command validation..."
echo "📦 Using image tag: $IMAGE_TAG"
echo "🚀 Running command: docker run --rm $IMAGE_TAG version"

# Запуск команды и захват вывода
output=$(docker run --rm "$IMAGE_TAG" version 2>&1)
echo "📥 Raw command output: $output"

# Проверка наличия ожидаемого сообщения об ошибке
echo "🔍 Checking for expected error message: 'Error: YC_TOKEN must be set'"
if echo "$output" | grep -q "Error: YC_TOKEN must be set"; then
    echo "✅ Expected error message found"
    exit 0
else
    echo "❌ Expected error message not found"
    exit 1
fi