## Purpose

Defines how the container accepts Yandex Cloud credentials for Terraform using only provider environment variables, for both user IAM tokens and service-account key files.

## ADDED Requirements

### Requirement: Credential presence gate
The container entrypoint MUST require that at least one of `YC_TOKEN` or `YC_SERVICE_ACCOUNT_KEY_FILE` is set before starting Terraform. If neither is set, the entrypoint MUST exit with a non-zero status and print an error that names both supported variables.

#### Scenario: Missing credentials
- **WHEN** the container is started with neither `YC_TOKEN` nor `YC_SERVICE_ACCOUNT_KEY_FILE` set
- **THEN** Terraform MUST NOT run and the process MUST fail with an error mentioning both `YC_TOKEN` and `YC_SERVICE_ACCOUNT_KEY_FILE`

### Requirement: IAM token authentication
When `YC_TOKEN` is set and `YC_SERVICE_ACCOUNT_KEY_FILE` is not set, the entrypoint MUST leave `YC_TOKEN` available to the Terraform Yandex provider and MUST start Terraform without configuring the Yandex Cloud CLI.

#### Scenario: User IAM token path
- **WHEN** the container is started with a non-empty `YC_TOKEN` and without `YC_SERVICE_ACCOUNT_KEY_FILE`
- **THEN** the entrypoint MUST exec Terraform with `YC_TOKEN` still set in the environment

### Requirement: Service account key authentication
When `YC_SERVICE_ACCOUNT_KEY_FILE` is set, the entrypoint MUST verify that the path refers to an existing file. If the file is missing, the entrypoint MUST exit with a non-zero status and MUST NOT start Terraform. On success, the entrypoint MUST start Terraform with `YC_SERVICE_ACCOUNT_KEY_FILE` available to the provider.

#### Scenario: Valid key file
- **WHEN** `YC_SERVICE_ACCOUNT_KEY_FILE` points to an existing file
- **THEN** the entrypoint MUST exec Terraform without requiring `YC_TOKEN`

#### Scenario: Missing key file
- **WHEN** `YC_SERVICE_ACCOUNT_KEY_FILE` is set but the path does not exist
- **THEN** the entrypoint MUST fail with an error that includes the path and MUST NOT start Terraform

### Requirement: Prefer key file when both credentials are set
If both `YC_TOKEN` and `YC_SERVICE_ACCOUNT_KEY_FILE` are set and the key file exists, the entrypoint MUST unset `YC_TOKEN` before starting Terraform so only one provider auth method remains.

#### Scenario: Both credentials provided
- **WHEN** both `YC_TOKEN` and a valid `YC_SERVICE_ACCOUNT_KEY_FILE` are set
- **THEN** Terraform MUST be started without `YC_TOKEN` in the environment and with `YC_SERVICE_ACCOUNT_KEY_FILE` set

### Requirement: Reject deprecated OAuth-shaped tokens
When authenticating via `YC_TOKEN` only, if the token matches the deprecated OAuth prefix pattern `y[0-3]_*`, the entrypoint MUST exit with a non-zero status and MUST instruct the caller to use an IAM token or a service account key.

#### Scenario: OAuth token rejected
- **WHEN** only `YC_TOKEN` is set and its value matches `y[0-3]_*`
- **THEN** the entrypoint MUST fail with an error stating OAuth tokens are not supported

### Requirement: No Yandex Cloud CLI configuration
The entrypoint MUST NOT invoke the Yandex Cloud CLI to set service-account key, cloud id, folder id, or any other profile values. Cloud and folder context MUST be left to provider environment variables (`YC_CLOUD_ID`, `YC_FOLDER_ID`) or Terraform configuration supplied by the caller.

#### Scenario: Cloud and folder via env only
- **WHEN** `YC_CLOUD_ID` and/or `YC_FOLDER_ID` are set alongside valid credentials
- **THEN** the entrypoint MUST start Terraform without running `yc config` commands
