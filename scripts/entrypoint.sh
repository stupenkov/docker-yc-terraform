#!/bin/bash
set -euo pipefail

# Yandex Cloud OAuth tokens are no longer accepted for new auth (since 2026-06-01).
# Terraform provider expects an IAM token in YC_TOKEN, or a service account key file.
# See: https://yandex.cloud/en/docs/terraform/authentication

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
	yc config set service-account-key "${YC_SERVICE_ACCOUNT_KEY_FILE}"
elif [[ "${YC_TOKEN}" == y[0-3]_* ]]; then
	echo "Error: OAuth tokens are no longer supported. Use an IAM token from 'yc iam create-token' (YC_TOKEN) or a service account key (YC_SERVICE_ACCOUNT_KEY_FILE)."
	exit 1
elif [[ "${YC_TOKEN}" != t1.* ]]; then
	echo "Warning: YC_TOKEN does not look like an IAM token (expected prefix 't1.'). Continuing anyway."
fi

if [[ -n "${YC_CLOUD_ID:-}" ]]; then
	yc config set cloud-id "${YC_CLOUD_ID}"
fi

if [[ -n "${YC_FOLDER_ID:-}" ]]; then
	yc config set folder-id "${YC_FOLDER_ID}"
fi

exec /bin/terraform "$@"
