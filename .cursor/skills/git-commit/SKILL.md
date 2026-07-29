---
name: git-commit
description: >-
  Create git commits and topic branches using Conventional Commits for
  release-please and this repo's .github CI/CD. Use when the user asks to
  commit, create a commit, write a commit message, or prepare changes for a PR.
---

# Git Commit

Follow this workflow whenever creating a commit in this repository.

Releases are driven by [release-please](.github/workflows/release.yml) on pushes
to `main`. CI (lint, scan, runtime validation) runs on pull requests targeting
`main`. Commits must use Conventional Commits so release-please can version and
changelog correctly. Do not commit directly on `main`.

## Before anything else: branch check

1. Run `git branch --show-current` (or `git status`).
2. If the current branch is `main` (or `master`):
   - **Do not commit on `main`.**
   - Sync with remote first:
     ```bash
     git fetch origin
     git pull --ff-only origin main
     ```
   - Create and switch to a topic branch (see [Branch naming](#branch-naming)).
   - Only then stage and commit.
3. If already on a topic branch, proceed to the commit workflow. Optionally
   rebase/merge latest `origin/main` if the branch is stale and the user wants
   it updated.

## Branch naming

Format: `<type>/<short-kebab-description>`

| Type | When |
|------|------|
| `feat/` | New user-facing capability |
| `fix/` | Bug fix |
| `docs/` | Documentation only |
| `chore/` | Tooling, CI, deps, non-user-facing maintenance |
| `refactor/` | Internal restructuring without behavior change |
| `test/` | Tests only |
| `ci/` | GitHub Actions / workflow changes |

Rules:
- Lowercase only; kebab-case description; no spaces.
- Keep the description short and specific (e.g. `fix/iam-token-auth`, `docs/readme-iam-review`).
- Match the commit type when possible (a `fix:` commit → `fix/...` branch).

Examples:
```bash
git checkout -b feat/add-compose-example
git checkout -b fix/publish-tag-filter
git checkout -b chore/update-actions
```

## Commit message format (Conventional Commits)

Required by release-please (`.github/workflows/release.yml`):

```
<type>[optional scope]: <description>

[optional body]
```

### Types that affect releases

| Type | Release-please effect |
|------|------------------------|
| `feat` | Minor version bump |
| `fix` | Patch version bump |
| `feat!` / `fix!` or footer `BREAKING CHANGE:` | Major version bump |
| `chore`, `docs`, `ci`, `test`, `refactor`, `style`, `perf` | No version bump (unless breaking) |

### Message rules

- Subject: imperative mood, lowercase after the type, no trailing period.
- Focus on **why**, not a file list; 1–2 sentences max in the body if needed.
- Optional scope in parentheses when it clarifies area: `fix(release):`, `ci(publish):`.
- Match existing history style, e.g. `fix: switch auth from OAuth to IAM token or SA key`.
- Do **not** create empty commits.
- Do **not** commit secrets (`.env`, key JSON, credentials). Warn if the user asks to include them.

### Examples

```
feat: add runtime validation workflow

fix: switch auth from OAuth to IAM token or SA key

fix(release): drop include-component-in-tag from workflow

docs: clarify IAM auth and align README with image usage

chore: update publish.yml tag pattern
```

## Commit workflow

Only create a commit when the user explicitly asks to commit.

### 1. Inspect state (run in parallel)

```bash
git status
git diff
git diff --staged
git log -5 --oneline
```

### 2. Draft the message

- Analyze staged + unstaged changes that will be included.
- Choose the correct Conventional Commit `type` (and scope if useful).
- Warn and exclude files that look like secrets.

### 3. Stage and commit

```bash
git add <relevant-files>
git commit -m "$(cat <<'EOF'
<type>[optional scope]: <description>

EOF
)"
```

Always pass the message via a HEREDOC as above.

### 4. Verify

```bash
git status
```

If a pre-commit hook fails: fix the issue and create a **new** commit. Do not amend unless the amend rules below allow it.

## Git safety protocol

- **Never** update git config.
- **Never** use destructive/irreversible commands (`push --force`, `hard reset`, etc.) unless the user explicitly requests them.
- **Never** skip hooks (`--no-verify`, `--no-gpg-sign`, etc.) unless the user explicitly requests it.
- **Never** force-push to `main`/`master`; warn if asked.
- **Never** use interactive git flags (`-i`, e.g. `rebase -i`, `add -i`).
- **Do not push** unless the user explicitly asks to push.
- **Do not commit** unless the user explicitly asks to commit.

### Amend — only when all are true

1. User explicitly requested amend, **or** the commit succeeded but a pre-commit hook auto-modified files that must be included.
2. `HEAD` was created by you in this conversation (`git log -1 --format='%an %ae'`).
3. The commit has **not** been pushed (`git status` shows branch ahead of remote).

If the commit failed or was rejected by a hook: **never amend** — fix and make a new commit. If already pushed: **never amend** unless the user explicitly requests it (implies force push).

## Quick checklist

```
- [ ] Not on main/master (or synced main + new topic branch created)
- [ ] Branch named type/short-kebab-description
- [ ] Secrets excluded
- [ ] Message is Conventional Commit (release-please compatible)
- [ ] HEREDOC used for commit message
- [ ] git status clean for intended files after commit
- [ ] No push unless user asked
```
