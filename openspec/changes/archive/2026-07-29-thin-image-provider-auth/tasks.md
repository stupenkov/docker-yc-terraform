## 1. Thin the Docker image

- [x] 1.1 Remove the Yandex Cloud CLI install from `Dockerfile` (curl install script, `yc` binary move, `yc version` check)
- [x] 1.2 Remove unused `/home/appuser/.ssh` setup from `Dockerfile` if still present
- [x] 1.3 Confirm `config/.terraformrc`, `TF_CLI_CONFIG_FILE`, non-root user, and entrypoint wiring remain intact

## 2. Entrypoint provider-auth only

- [x] 2.1 Remove all `yc config set` calls from `scripts/entrypoint.sh`
- [x] 2.2 Keep credential presence gate, key-file existence check, prefer-key-over-token (`unset YC_TOKEN`), OAuth rejection, and optional non-`t1.` warning
- [x] 2.3 Ensure entrypoint still `exec`s `/bin/terraform` with caller arguments after checks pass

## 3. Docs and validation

- [x] 3.1 Update `README.md` for the thin-image contract: two auth modes, no in-image `yc`, caller responsible for minting `YC_TOKEN`
- [x] 3.2 Rename `tests/validate-yc-token.sh` (e.g. to `tests/validate-runtime-smoke.sh`) and update `.github/workflows/runtime-validation.yml` to call the new path
- [x] 3.3 Extend the smoke script to assert `yc` is not on `PATH` in the built image (in addition to the missing-credentials error)
- [x] 3.4 Delete unused `GitVersion.yml`
- [x] 3.5 Verify via local Docker build when available, or rely on CI `runtime-validation`: missing creds fails as expected; `yc` absent; optional smoke that Terraform runs when a dummy `YC_TOKEN` is set
