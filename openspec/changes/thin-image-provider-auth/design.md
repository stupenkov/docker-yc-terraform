## Context

See proposal.md for motivation. Today the image is based on `hashicorp/terraform`, installs `yc` via the upstream install script, and `scripts/entrypoint.sh` copies credentials into `yc config` before `exec terraform`. The Terraform Yandex provider already reads `YC_TOKEN`, `YC_SERVICE_ACCOUNT_KEY_FILE`, `YC_CLOUD_ID`, and `YC_FOLDER_ID` from the environment, so the CLI wiring is redundant for the supported workflows.

Implementation of the thin image/entrypoint/README is largely done; remaining work is smoke-test rename/coverage, dead-config cleanup, and image verification when Docker is available (or via CI).

## Goals / Non-Goals

**Goals:**

- Align runtime auth with the provider’s env-var contract only.
- Shrink and simplify the image by removing `yc` and related entrypoint logic.
- Preserve clear fail-fast errors for missing credentials, missing key files, and deprecated OAuth-shaped tokens.
- Keep `.terraformrc` / Yandex provider mirror behavior unchanged.
- Keep a small runtime smoke in CI that matches `provider-auth` + `thin-runtime` (missing creds + no `yc`).

**Non-Goals:**

- Auto-minting IAM tokens inside the container.
- First-run `yc init` or persistent CLI profile volumes.
- Changing how callers obtain `YC_TOKEN` or SA keys outside the image.
- Enabling compute-instance metadata auth (neither env set) in this change—keep the explicit credential gate.
- Broader CI workflow consolidation (optional follow-up).
- Expanding the smoke suite to OAuth-reject / SA-key-missing / happy-path `terraform version` scenarios in this change.

## Decisions

### 1. Remove `yc` from the image entirely

- **Choice:** Delete the install step and any runtime dependency on `yc`.
- **Why:** Provider auth does not need it; install script adds size and supply-chain surface.
- **Alternatives considered:** Keep `yc` for optional auto-token / in-container CLI → rejected; expands product scope beyond a thin Terraform runner.

### 2. Entrypoint validates, then execs Terraform

- **Choice:** Keep a small bash entrypoint for presence checks, key-file existence, OAuth rejection, and “prefer key file if both set” (`unset YC_TOKEN`).
- **Why:** Early, actionable errors beat opaque provider failures; matches current UX users already see in CI smoke tests.
- **Alternatives considered:** Entrypoint = `terraform` only → simpler but worse missing-cred UX; keep `yc config set` → unnecessary once CLI is gone.

### 3. Two supported auth modes only

- **Choice:** Document and implement `YC_TOKEN` (user/dev IAM) and `YC_SERVICE_ACCOUNT_KEY_FILE` (CI/SA).
- **Why:** Matches Yandex Terraform authentication docs and the project goal of both personas.
- **Alternatives considered:** Metadata-only auth without env → useful on YC VMs but conflicts with current “must set credentials” gate; defer.

### 4. Soft warning for non-`t1.` tokens stays optional

- **Choice:** Keep the existing warning when `YC_TOKEN` does not look like `t1.*` (except hard-fail OAuth prefixes); do not invent stricter validation.
- **Why:** Avoid false negatives on unexpected but valid token shapes; OAuth hard-fail already covers the known breaking case.

### 5. Drop unused `.ssh` directory setup if still present

- **Choice:** Remove creating `/home/appuser/.ssh` unless a concrete consumer appears.
- **Why:** Dead weight unrelated to Terraform-for-YC.
- **Alternatives considered:** Leave as-is → harmless but noisy.

### 6. Keep runtime smoke script; rename and cover thin-runtime

- **Choice:** Keep a standalone script under `tests/` (do not inline solely into the workflow). Rename away from `validate-yc-token.sh` (e.g. `validate-runtime-smoke.sh`). Assert: (1) missing credentials error string, (2) `yc` not found on `PATH` (via overridden entrypoint/`sh -c`).
- **Why:** The check is still needed for the credential gate; the old name is misleading after dropping in-image `yc`; a second assert cheaply covers `thin-runtime`. A file keeps local `./tests/... <tag>` DX.
- **Alternatives considered:** Delete the script and rely only on workflow steps → fewer files, worse local reuse; drop smoke entirely → rejects the only runtime gate in CI.

### 7. Delete unused `GitVersion.yml`

- **Choice:** Remove `GitVersion.yml` from the repo.
- **Why:** Nothing references it; releases use release-please.
- **Alternatives considered:** Leave as harmless cruft → adds confusion about the versioning source of truth.

## Risks / Trade-offs

- **[BREAKING] Users who ran `yc` inside the image** → Mitigation: call out in README/changelog; no replacement CLI in-image.
- **[DX] Obtaining user IAM tokens still needs tooling outside the image** → Mitigation: document that minting `YC_TOKEN` is the caller’s responsibility; image only consumes it.
- **[Behavior] `YC_CLOUD_ID` / `YC_FOLDER_ID` no longer mirrored into `yc` config** → Mitigation: none needed for Terraform; provider already reads those env vars. Only non-Terraform `yc` usage would care, and that goes away with this change.
- **[Tests] Smoke must stay in sync with entrypoint + image contents** → Mitigation: renamed script checks missing-creds message and absence of `yc`; workflow path updated with the rename.

## Migration Plan

1. Ship as a semver-major or clearly marked breaking release note (image no longer includes `yc`).
2. Callers using SA keys: usually no change beyond confirming they do not rely on in-container `yc`.
3. Callers using IAM tokens: keep passing `YC_TOKEN` (and optional `YC_CLOUD_ID` / `YC_FOLDER_ID`); stop expecting `yc` in the container.
4. Rollback: previous image tags still contain `yc` if needed temporarily.

## Open Questions

- None that block the remaining tasks; metadata-auth without credentials remains a possible follow-up change.
