## Why

The image installs the Yandex Cloud CLI (`yc`) and the entrypoint mirrors credentials into `yc config`, but the Terraform Yandex provider already authenticates from `YC_TOKEN` and `YC_SERVICE_ACCOUNT_KEY_FILE` alone. That extra layer adds image size, supply-chain surface, and confusion without simplifying either the user (dev) or service-account (CI) path documented by Yandex Cloud.

## What Changes

- **BREAKING**: Remove the Yandex Cloud CLI (`yc`) from the Docker image.
- **BREAKING**: Stop calling `yc config set` in the entrypoint; rely on provider environment variables only.
- Keep two authentication modes aligned with the Terraform provider:
  - `YC_TOKEN` — IAM token for user/dev workflows
  - `YC_SERVICE_ACCOUNT_KEY_FILE` — authorized key file for CI/automation
- Keep a thin entrypoint that validates credentials are present (and rejects deprecated OAuth-shaped tokens), then `exec`s Terraform.
- Update README for the thin-image contract (caller mints `YC_TOKEN` outside the image).
- Rename the runtime smoke script (misleading `validate-yc-token` name) and extend it to assert missing-credentials behavior **and** that `yc` is absent from `PATH`; update `runtime-validation.yml` accordingly.
- Remove unused `GitVersion.yml` (versioning is via release-please).
- Non-goals: auto-minting IAM tokens inside the image, mounting a `yc` profile volume, requiring a local `yc` install as part of the image contract, or expanding CI into full OAuth/SA-key scenario suites.

## Capabilities

### New Capabilities

- `provider-auth`: Container runtime authentication contract for Terraform via `YC_TOKEN` and/or `YC_SERVICE_ACCOUNT_KEY_FILE`, without embedding or configuring the Yandex Cloud CLI.
- `thin-runtime`: Docker image contents limited to Terraform, provider mirror config, and a thin entrypoint (no `yc` CLI).

### Modified Capabilities

- (none — no existing specs under `openspec/specs/`)

## Impact

- `Dockerfile`: drop `yc` install and unused `.ssh` setup; keep provider mirror config and non-root user.
- `scripts/entrypoint.sh`: remove `yc config` usage; keep credential presence checks and OAuth rejection.
- `README.md`: document the two auth paths as the supported contract; clarify that minting `YC_TOKEN` is the caller's responsibility.
- `tests/*` + `.github/workflows/runtime-validation.yml`: rename smoke script; keep missing-credentials check; add no-`yc`-on-`PATH` check.
- `GitVersion.yml`: delete (unused; release-please owns releases).
- Downstream users who relied on `yc` inside the container must stop doing so (**BREAKING**).
