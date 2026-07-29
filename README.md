# Yandex Cloud Terraform Docker Container

![Docker Pulls](https://img.shields.io/docker/pulls/stupean/yandex-terraform)
![Docker Image Size](https://img.shields.io/docker/image-size/stupean/yandex-terraform)
![License](https://img.shields.io/github/license/stupenkov/docker-yc-terraform)

**Docker container for Yandex Cloud infrastructure management with Terraform**

[GitHub Repository](https://github.com/stupenkov/docker-yc-terraform)

## Overview

This Docker container provides a ready-to-use environment for working with Yandex Cloud infrastructure using Terraform.

> **Breaking change:** OAuth tokens are no longer supported by Yandex Cloud (since 2026-06-01). Use an [IAM token](https://yandex.cloud/en/docs/iam/concepts/authorization/iam-token) or a [service account authorized key](https://yandex.cloud/en/docs/iam/concepts/authorization/key).

## Prerequisites

- Docker installed on your system
- Yandex Cloud account with appropriate permissions
- One of:
  - [IAM token](https://yandex.cloud/en/docs/iam/concepts/authorization/iam-token) — requires a locally configured [`yc` CLI](https://yandex.cloud/en/docs/cli/) to run `yc iam create-token`
  - [Service account authorized key](https://yandex.cloud/en/docs/iam/operations/authorized-key/create) JSON file (better for automation; no 12-hour expiry)

## Getting Started

### 1. Get the image

Pull from Docker Hub:

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

Provider credentials can come entirely from environment variables — a minimal config is enough:

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

### 3. Obtain Yandex Cloud credentials

| Variable                      | Description                                                                                                                                     | Required                                      |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| `YC_TOKEN`                    | [IAM token](https://yandex.cloud/en/docs/iam/operations/iam-token/create) from `yc iam create-token` (lives ~12 hours)                          | One of `YC_TOKEN` or `YC_SERVICE_ACCOUNT_KEY_FILE` |
| `YC_SERVICE_ACCOUNT_KEY_FILE` | Path inside the container to a [service account authorized key](https://yandex.cloud/en/docs/iam/operations/authorized-key/create) JSON file    | One of `YC_TOKEN` or `YC_SERVICE_ACCOUNT_KEY_FILE` |
| `YC_CLOUD_ID`                 | Cloud ID (`yc config get cloud-id`)                                                                                                             | Recommended for `plan` / `apply` (unless set in provider) |
| `YC_FOLDER_ID`                | Folder ID (`yc config get folder-id`)                                                                                                           | Recommended for `plan` / `apply` (unless set in provider) |
| `YC_ZONE`                     | Default zone for the Terraform provider (e.g. `ru-central1-a`); read by the provider, not by this image's entrypoint                            | No                                            |

Get IDs and an IAM token from a machine where `yc` is already authenticated:

```bash
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
export YC_TOKEN=$(yc iam create-token)   # expires in ~12 hours
```

### 4. Basic usage

Run any Terraform command (project dir mounted at `/app`):

```bash
docker run -it --rm \
  -e YC_TOKEN="$(yc iam create-token)" \
  -e YC_CLOUD_ID="$YC_CLOUD_ID" \
  -e YC_FOLDER_ID="$YC_FOLDER_ID" \
  -v "$(pwd)":/app \
  stupean/yandex-terraform <command>
```

Examples: `init`, `plan`, `apply`, `destroy`.

> Creating a fresh IAM token per `docker run` (as above) avoids using an expired export. If you reuse `export YC_TOKEN=...`, refresh it when it expires (~12 hours).

Authenticate with a service account key instead:

```bash
docker run -it --rm \
  -e YC_SERVICE_ACCOUNT_KEY_FILE=/keys/sa-key.json \
  -e YC_CLOUD_ID="$YC_CLOUD_ID" \
  -e YC_FOLDER_ID="$YC_FOLDER_ID" \
  -v "$(pwd)":/app \
  -v /path/to/sa-key.json:/keys/sa-key.json:ro \
  stupean/yandex-terraform plan
```

## Troubleshooting

### Common issues

1. **"YC_TOKEN or YC_SERVICE_ACCOUNT_KEY_FILE must be set"**: Pass an IAM token or mount a service account key
2. **"OAuth tokens are no longer supported"**: Use `yc iam create-token` or a service account key — not an OAuth token
3. **Permission errors**: Check that your token/key has sufficient roles in Yandex Cloud
4. **Network issues**: Verify you can reach Yandex Cloud APIs from your network
5. **IAM token expired**: Tokens live up to ~12 hours; run `yc iam create-token` again

### Debug mode

Enable Terraform provider/client logs with `TF_LOG`:

```bash
docker run -it --rm \
  -e TF_LOG=DEBUG \
  -e YC_TOKEN="$(yc iam create-token)" \
  -e YC_CLOUD_ID="$YC_CLOUD_ID" \
  -e YC_FOLDER_ID="$YC_FOLDER_ID" \
  -v "$(pwd)":/app \
  stupean/yandex-terraform plan
```

## Advanced usage

### Shell alias

Add to `~/.bashrc` or `~/.zshrc`. Refresh `YC_TOKEN` periodically (`export YC_TOKEN=$(yc iam create-token)`), or prefer a key file for longer sessions:

```bash
# IAM token
alias yterraform='docker run -it --rm \
  -e YC_TOKEN=$YC_TOKEN \
  -e YC_CLOUD_ID=$YC_CLOUD_ID \
  -e YC_FOLDER_ID=$YC_FOLDER_ID \
  -v "$(pwd)":/app \
  stupean/yandex-terraform'

# Service account key (mount host key into the container)
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

Create `docker-compose.yml`:

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
export YC_TOKEN=$(yc iam create-token)
docker compose run --rm yc-terraform plan
```

## Support

- [Yandex Cloud Documentation](https://yandex.cloud/en/docs)
- [Terraform Yandex Cloud Provider](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)
