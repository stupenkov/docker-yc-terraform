## Purpose

Defines the Docker image as a thin Terraform runtime for Yandex Cloud: Terraform, provider mirror configuration, and a credential-checking entrypoint—without embedding the Yandex Cloud CLI.

## ADDED Requirements

### Requirement: Image does not include Yandex Cloud CLI
The published container image MUST NOT contain the `yc` executable on `PATH` (or at the previous install location used by this project).

#### Scenario: yc binary absent
- **WHEN** a shell in the built image searches for `yc` on `PATH`
- **THEN** `yc` MUST NOT be found

### Requirement: Terraform remains the primary command
The container entrypoint MUST ultimately execute Terraform with the caller-supplied arguments after credential checks succeed.

#### Scenario: Forward terraform args
- **WHEN** the container is started with valid credentials and arguments such as `version`
- **THEN** those arguments MUST be passed to Terraform

### Requirement: Provider registry mirror retained
The image MUST continue to ship Terraform CLI config that uses the Yandex Cloud Terraform provider network mirror for `registry.terraform.io/*/*`.

#### Scenario: Mirror config present
- **WHEN** the image is built
- **THEN** the configured `TF_CLI_CONFIG_FILE` (or equivalent) MUST point at a config that enables the Yandex Cloud network mirror for Terraform providers
