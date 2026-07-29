#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "❌ Usage: $0 <image-tag>"
    exit 1
fi

IMAGE_TAG="$1"

echo "🔍 Starting version command validation..."
echo "📦 Using image tag: $IMAGE_TAG"
echo "🚀 Running command: docker run --rm $IMAGE_TAG version"

output=$(docker run --rm "$IMAGE_TAG" version 2>&1 || true)

echo "📥 Raw output:"
echo "$output"

expected_msg="Error: YC_TOKEN or YC_SERVICE_ACCOUNT_KEY_FILE must be set"
echo "🔍 Checking for expected error message: '$expected_msg'"

if echo "$output" | grep -q "$expected_msg"; then
    echo "✅ Expected error message found"
    exit 0
else
    echo "❌ Expected error message not found"
    exit 1
fi