# Configure Git Signing for Claude

Ensure all commits are signed with Claude's identity.

## Setup

Run once to configure:

```bash
git config user.name "GitHub Copilot"
git config user.email "copilot@github.com"
git config commit.gpgSign false  # We sign via author metadata, not GPG
```

## Verification

To verify configuration:

```bash
git config --local user.name
git config --local user.email
```

Expected output:
```
GitHub Copilot
copilot@github.com
```

## Auto-apply on project setup

Add this to your project initialization script or to `pubspec.yaml` post-gen hook if needed.

## Commit template (optional)

Create `.gitmessage` template with commit format guidelines:

```
feat/fix/docs/refactor: short summary (50 chars max)

- Detailed change 1
- Detailed change 2

Fixes: (GitHub issue if applicable)
```

Then apply:
```bash
git config commit.template .gitmessage
```


