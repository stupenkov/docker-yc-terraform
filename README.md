# Yandex Cloud Terraform Docker Container

![Docker Pulls](https://img.shields.io/docker/pulls/stupean/yandex-terraform)
![Docker Image Size](https://img.shields.io/docker/image-size/stupean/yandex-terraform)
![License](https://img.shields.io/github/license/stupenkov/docker-yc-terraform)

**Docker container for Yandex Cloud infrastructure management with Terraform**

[GitHub Repository](https://github.com/stupenkov/docker-yc-terraform)

## Overview

This Docker container provides a ready-to-use environment for working with Yandex Cloud infrastructure using Terraform.

## Prerequisites

- Docker installed on your system
- Yandex Cloud account with appropriate permissions
- OAuth token for Yandex Cloud API access

## Getting Started

### 1. Build the Docker Image

```bash
docker build -t yandex-terraform .
```

### 2. Prepare Your Environment

Create a directory for your Terraform configuration:

```bash
mkdir my-terraform-project
cd my-terraform-project
```

### 3. Obtain Yandex Cloud Credentials

| Variable       | Description                                                                                     | Required |
| -------------- | ----------------------------------------------------------------------------------------------- | -------- |
| `YC_TOKEN`     | [Yandex Cloud OAuth token](https://yandex.cloud/en/docs/iam/concepts/authorization/oauth-token) | Yes      |
| `YC_CLOUD_ID`  | Yandex Cloud ID                                                                                 | No       |
| `YC_FOLDER_ID` | Yandex Cloud Folder ID                                                                          | No       |
| `YC_ZONE`      | Default zone (default: ru-central1-a)                                                           | No       |

### 4. Basic Usage

#### Run Terraform commands:

```bash
docker run -it --rm \
  -e YC_TOKEN=your_oauth_token_here \
  -e YC_CLOUD_ID=your_cloud_id_here \
  -e YC_FOLDER_ID=your_folder_id_here \
  -v $(pwd):/app \
  yandex-terraform [command]
```

#### Example commands:

```bash
# Initialize Terraform
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  -v $(pwd):/app \
  yandex-terraform init

# Plan infrastructure changes
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  -v $(pwd):/app \
  yandex-terraform plan

# Apply changes
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  -v $(pwd):/app \
  yandex-terraform apply

# Destroy infrastructure
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  -v $(pwd):/app \
  yandex-terraform destroy
```

## Volume Mounting

Mount your local directory to `/app` in the container to persist Terraform state and configuration:

```bash
-v $(pwd):/app
```

## Troubleshooting

### Common Issues

1. **"YC_TOKEN must be set" error**: Ensure you pass the YC_TOKEN environment variable
2. **Permission errors**: Check that your token has sufficient permissions in Yandex Cloud
3. **Network issues**: Verify you can access Yandex Cloud APIs from your network

### Debug Mode

Run container with debug output:

```bash
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -v $(pwd):/app \
  yandex-terraform plan -verbose
```

## Advanced Usage

### Create an alias for convenience

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias yterraform='docker run -it --rm -e YC_TOKEN=$YC_TOKEN -e YC_CLOUD_ID=$YC_CLOUD_ID -e YC_FOLDER_ID=$YC_FOLDER_ID -v $(pwd):/app yandex-terraform'
```

Then use:

```bash
yterraform plan
```

### Using Docker Compose

Create `docker-compose.yml`:

```yaml
version: "3.8"
services:
  yc-terraform:
    image: yandex-terraform
    environment:
      - YC_TOKEN=${YC_TOKEN}
      - YC_CLOUD_ID=${YC_CLOUD_ID}
      - YC_FOLDER_ID=${YC_FOLDER_ID}
    volumes:
      - .:/app
    working_dir: /app
```

Use with:

```bash
docker-compose run --rm yc-terraform plan
```

## Support

For Yandex Cloud specific issues, refer to:

- [Yandex Cloud Documentation](https://cloud.yandex.com/docs)
- [Terraform Yandex Cloud Provider](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)

For Docker issues, refer to Docker documentation and ensure your Docker installation is up to date.
