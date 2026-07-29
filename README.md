# Yandex Cloud Terraform Docker Container

![Docker Pulls](https://img.shields.io/docker/pulls/stupean/yandex-terraform)
![Docker Image Size](https://img.shields.io/docker/image-size/stupean/yandex-terraform)
![License](https://img.shields.io/github/license/stupenkov/docker-yc-terraform)

**Thin Docker runtime for Terraform against Yandex Cloud**

[GitHub Repository](https://github.com/stupenkov/docker-yc-terraform)

## Overview

This image packages Terraform with the [Yandex Cloud provider mirror](https://yandex.cloud/en/docs/terraform/quickstart#configure-provider) and a small entrypoint that checks credentials, then runs Terraform.

Authentication follows the [Terraform provider env-var contract](https://yandex.cloud/en/docs/terraform/authentication):

| Mode | Variable | Typical use |
| ---- | -------- | ----------- |
| IAM token | `YC_TOKEN` | Dev / user identity |
| Service account key | `YC_SERVICE_ACCOUNT_KEY_FILE` | CI / automation |

The image does **not** include the Yandex Cloud CLI (`yc`). Minting an IAM token (or creating an SA key) is the caller's responsibility outside the container.

> **Breaking change:** This image no longer ships `yc`. Pass credentials via environment variables only. OAuth tokens are not supported (since 2026-06-01)—use an [IAM token](https://yandex.cloud/en/docs/iam/concepts/authorization/iam-token) or a [service account authorized key](https://yandex.cloud/en/docs/iam/concepts/authorization/key).

## Prerequisites

- Docker
- Yandex Cloud account with appropriate permissions
- One of:
  - An [IAM token](https://yandex.cloud/en/docs/iam/concepts/authorization/iam-token) in `YC_TOKEN` (often obtained with [`yc iam create-token`](https://yandex.cloud/en/docs/cli/) on a machine that has the CLI, or another supported method)
  - A [service account authorized key](https://yandex.cloud/en/docs/iam/operations/authentication/manage-authorized-keys#create-authorized-key) JSON file (preferred for CI; no 12-hour expiry)

## Getting Started

### 1. Get the image

```bash
docker pull stupean/yandex-terraform
```

Or build locally:

```bash
docker build -t stupean/yandex-terraform .
```

### 2. Prepare your Terraform project

```bash
mkdir my-terraform-project
cd my-terraform-project
```

Mount the project into the container as `/app` (`-v $(pwd):/app`) so state and configs persist on the host.

Minimal provider config (credentials come from the environment):

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {}
```

### 3. Credentials

| Variable | Description | Required |
| -------- | ----------- | -------- |
| `YC_TOKEN` | [IAM token](https://yandex.cloud/en/docs/iam/operations/iam-token/create) (lives ~12 hours) | One of `YC_TOKEN` or `YC_SERVICE_ACCOUNT_KEY_FILE` |
| `YC_SERVICE_ACCOUNT_KEY_FILE` | Path **inside the container** to an SA authorized key JSON | One of `YC_TOKEN` or `YC_SERVICE_ACCOUNT_KEY_FILE` |
| `YC_CLOUD_ID` | Cloud ID | Recommended for `plan` / `apply` (unless set in provider) |
| `YC_FOLDER_ID` | Folder ID | Recommended for `plan` / `apply` (unless set in provider) |
| `YC_ZONE` | Default zone (e.g. `ru-central1-a`); read by the provider | No |

Example of obtaining values on a host that has `yc` (optional tooling—not part of this image):

```bash
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
export YC_TOKEN=$(yc iam create-token)   # expires in ~12 hours
```

### 4. Basic usage

**Dev / IAM token:**

```bash
docker run -it --rm \
  -e YC_TOKEN="$YC_TOKEN" \
  -e YC_CLOUD_ID="$YC_CLOUD_ID" \
  -e YC_FOLDER_ID="$YC_FOLDER_ID" \
  -v "$(pwd)":/app \
  stupean/yandex-terraform <command>
```

Examples: `init`, `plan`, `apply`, `destroy`.

Refresh `YC_TOKEN` when it expires (~12 hours).

**CI / service account key:**

```bash
docker run -it --rm \
  -e YC_SERVICE_ACCOUNT_KEY_FILE=/keys/sa-key.json \
  -e YC_CLOUD_ID="$YC_CLOUD_ID" \
  -e YC_FOLDER_ID="$YC_FOLDER_ID" \
  -v "$(pwd)":/app \
  -v /path/to/sa-key.json:/keys/sa-key.json:ro \
  stupean/yandex-terraform plan
```

If both `YC_TOKEN` and `YC_SERVICE_ACCOUNT_KEY_FILE` are set, the entrypoint prefers the key file and unsets `YC_TOKEN`.

## Troubleshooting

### Common issues

1. **"YC_TOKEN or YC_SERVICE_ACCOUNT_KEY_FILE must be set"**: Pass an IAM token or mount a service account key
2. **"OAuth tokens are no longer supported"**: Use an IAM token or a service account key — not an OAuth token
3. **Permission errors**: Check that your token/key has sufficient roles in Yandex Cloud
4. **Network issues**: Verify you can reach Yandex Cloud APIs from your network
5. **IAM token expired**: Tokens live up to ~12 hours; mint a new `YC_TOKEN` outside the container

### Debug mode

```bash
docker run -it --rm \
  -e TF_LOG=DEBUG \
  -e YC_TOKEN="$YC_TOKEN" \
  -e YC_CLOUD_ID="$YC_CLOUD_ID" \
  -e YC_FOLDER_ID="$YC_FOLDER_ID" \
  -v "$(pwd)":/app \
  stupean/yandex-terraform plan
```

## Advanced usage

### Shell alias

```bash
# IAM token (export YC_TOKEN / YC_CLOUD_ID / YC_FOLDER_ID in your shell)
alias yterraform='docker run -it --rm \
  -e YC_TOKEN=$YC_TOKEN \
  -e YC_CLOUD_ID=$YC_CLOUD_ID \
  -e YC_FOLDER_ID=$YC_FOLDER_ID \
  -v "$(pwd)":/app \
  stupean/yandex-terraform'

# Service account key
alias yterraform-sa='docker run -it --rm \
  -e YC_SERVICE_ACCOUNT_KEY_FILE=/keys/sa-key.json \
  -e YC_CLOUD_ID=$YC_CLOUD_ID \
  -e YC_FOLDER_ID=$YC_FOLDER_ID \
  -v "$(pwd)":/app \
  -v "$YC_SA_KEY_HOST_PATH":/keys/sa-key.json:ro \
  stupean/yandex-terraform'
```

```bash
yterraform plan
# or
export YC_SA_KEY_HOST_PATH=/path/to/sa-key.json
yterraform-sa plan
```

### Docker Compose

```yaml
services:
  yc-terraform:
    image: stupean/yandex-terraform
    environment:
      YC_TOKEN: ${YC_TOKEN:-}
      YC_SERVICE_ACCOUNT_KEY_FILE: ${YC_SERVICE_ACCOUNT_KEY_FILE:-}
      YC_CLOUD_ID: ${YC_CLOUD_ID}
      YC_FOLDER_ID: ${YC_FOLDER_ID}
    volumes:
      - .:/app
      # Uncomment when using a service account key:
      # - ${YC_SA_KEY_HOST_PATH}:/keys/sa-key.json:ro
    working_dir: /app
```

```bash
docker compose run --rm yc-terraform plan
```

## Support

- [Yandex Cloud Terraform authentication](https://yandex.cloud/en/docs/terraform/authentication)
- [Terraform Yandex Cloud Provider](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)
