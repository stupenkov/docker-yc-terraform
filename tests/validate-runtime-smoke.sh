#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "❌ Usage: $0 <image-tag>"
    exit 1
fi

IMAGE_TAG="$1"

echo "🔍 Starting runtime smoke validation..."
echo "📦 Using image tag: $IMAGE_TAG"

# --- Missing credentials gate ---
echo "🚀 Running command: docker run --rm $IMAGE_TAG version"

output=$(docker run --rm "$IMAGE_TAG" version 2>&1 || true)

echo "📥 Raw output:"
echo "$output"

expected_msg="Error: YC_TOKEN or YC_SERVICE_ACCOUNT_KEY_FILE must be set"
echo "🔍 Checking for expected error message: '$expected_msg'"

if echo "$output" | grep -q "$expected_msg"; then
    echo "✅ Expected missing-credentials error found"
else
    echo "❌ Expected missing-credentials error not found"
    exit 1
fi

# --- yc absent from PATH (thin-runtime) ---
echo "🔍 Checking that yc is not on PATH in the image..."

if docker run --rm --entrypoint sh "$IMAGE_TAG" -c 'command -v yc' >/dev/null 2>&1; then
    echo "❌ yc was found on PATH; image must not include the Yandex Cloud CLI"
    exit 1
fi

echo "✅ yc is not on PATH"
echo "✅ Runtime smoke validation passed"
exit 0
