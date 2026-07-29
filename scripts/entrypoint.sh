#!/bin/bash
set -euo pipefail

# Terraform Yandex provider authenticates from env vars only.
# See: https://yandex.cloud/en/docs/terraform/authentication
# OAuth tokens are no longer accepted for new auth (since 2026-06-01).

if [[ -z "${YC_TOKEN:-}" && -z "${YC_SERVICE_ACCOUNT_KEY_FILE:-}" ]]; then
	echo "Error: YC_TOKEN or YC_SERVICE_ACCOUNT_KEY_FILE must be set"
	exit 1
fi

if [[ -n "${YC_SERVICE_ACCOUNT_KEY_FILE:-}" ]]; then
	if [[ ! -f "${YC_SERVICE_ACCOUNT_KEY_FILE}" ]]; then
		echo "Error: YC_SERVICE_ACCOUNT_KEY_FILE does not exist: ${YC_SERVICE_ACCOUNT_KEY_FILE}"
		exit 1
	fi
	# Provider accepts only one auth method; prefer the key file when both are present.
	unset YC_TOKEN
elif [[ "${YC_TOKEN}" == y[0-3]_* ]]; then
	echo "Error: OAuth tokens are no longer supported. Use an IAM token (YC_TOKEN) or a service account key (YC_SERVICE_ACCOUNT_KEY_FILE)."
	exit 1
elif [[ "${YC_TOKEN}" != t1.* ]]; then
	echo "Warning: YC_TOKEN does not look like an IAM token (expected prefix 't1.'). Continuing anyway."
fi

# YC_CLOUD_ID / YC_FOLDER_ID / YC_ZONE are read by the provider from the environment.

exec /bin/terraform "$@"
