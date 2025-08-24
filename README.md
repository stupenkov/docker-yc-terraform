# Yandex Cloud Terraform Docker Container

## Overview

This Docker container provides a ready-to-use environment for working with Yandex Cloud infrastructure using Terraform. It includes:
- Yandex Cloud CLI (`yc`)
- Terraform with Yandex Cloud provider
- Pre-configured Terraform templates
- Essential tools (curl, jq, git, SSH, etc.)

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

Get your credentials from Yandex Cloud Console:
- **YC_TOKEN**: [OAuth token](https://yandex.cloud/en/docs/iam/concepts/authorization/oauth-token)
- **YC_CLOUD_ID**: Cloud ID
- **YC_FOLDER_ID**: Folder ID

### 4. Basic Usage

#### Run Terraform commands:

```bash
docker run -it --rm \
  -e YC_TOKEN=your_oauth_token_here \
  -e YC_CLOUD_ID=your_cloud_id_here \
  -e YC_FOLDER_ID=your_folder_id_here \
  -v $(pwd):/app \
  yandex-terraform terraform [command]
```

#### Example commands:

```bash
# Initialize Terraform
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  -v $(pwd):/app \
  yandex-terraform terraform init

# Plan infrastructure changes
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  -v $(pwd):/app \
  yandex-terraform terraform plan

# Apply changes
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  -v $(pwd):/app \
  yandex-terraform terraform apply

# Destroy infrastructure
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  -v $(pwd):/app \
  yandex-terraform terraform destroy
```

### 5. Using Yandex Cloud CLI (yc)

```bash
# Check yc version
docker run -it --rm yandex-terraform yc version

# List available clouds
docker run -it --rm \
  -e YC_TOKEN=your_token \
  yandex-terraform yc resource-manager cloud list

# List compute instances
docker run -it --rm \
  -e YC_TOKEN=your_token \
  -e YC_CLOUD_ID=your_cloud_id \
  -e YC_FOLDER_ID=your_folder_id \
  yandex-terraform yc compute instance list
```

## Default Terraform Configuration

The container includes a default Terraform configuration:

**main.tf**:
```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token = var.yc_token
  zone  = "ru-central1-a"
}
```

**variables.tf**:
```hcl
variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud default zone"
  type        = string
  default     = "ru-central1-a"
}
```

## Environment Variables

| Variable       | Description                           | Required             |
| -------------- | ------------------------------------- | -------------------- |
| `YC_TOKEN`     | Yandex Cloud OAuth token              | Yes                  |
| `YC_CLOUD_ID`  | Yandex Cloud ID                       | No (but recommended) |
| `YC_FOLDER_ID` | Yandex Cloud Folder ID                | No (but recommended) |
| `YC_ZONE`      | Default zone (default: ru-central1-a) | No                   |

## Volume Mounting

Mount your local directory to `/app` in the container to persist Terraform state and configuration:

```bash
-v $(pwd):/app
```

## Security Best Practices

1. **Never hardcode credentials** in Dockerfiles or source code
2. **Use environment variables** for sensitive data
3. **Use .gitignore** to exclude sensitive files:
   ```
   *.tfstate
   *.tfstate.backup
   .terraform/
   terraform.tfvars
   .env
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
  yandex-terraform terraform plan -verbose
```

## Advanced Usage

### Create an alias for convenience

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias yterraform='docker run -it --rm -e YC_TOKEN=$YC_TOKEN -e YC_CLOUD_ID=$YC_CLOUD_ID -e YC_FOLDER_ID=$YC_FOLDER_ID -v $(pwd):/app yandex-terraform'
```

Then use:
```bash
yterraform terraform plan
```

### Using Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'
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
docker-compose run --rm yc-terraform terraform plan
```

## Support

For Yandex Cloud specific issues, refer to:
- [Yandex Cloud Documentation](https://cloud.yandex.com/docs)
- [Terraform Yandex Cloud Provider](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)

For Docker issues, refer to Docker documentation and ensure your Docker installation is up to date.