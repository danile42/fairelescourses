# GitHub Copilot Commit Signing

When GitHub Copilot makes commits, they should be attributed to the project author with Copilot listed as a co-author.

## How it works

- Project user commits are made under **your** identity (configured locally)
- Copilot commits are made using the script `.claude/scripts/commit-as-copilot.sh`, which adds a co-author trailer
- GitHub automatically recognizes the `Co-authored-by:` trailer and displays both authors on the commit

## For Copilot: Making a commit

Use the provided script instead of `git commit`:

```bash
./.claude/scripts/commit-as-copilot.sh "feat: description of the change

- Detail 1
- Detail 2"
```

The script automatically adds:
```
Co-authored-by: GitHub Copilot <copilot-agent@users.noreply.github.com>
```

## For the project author: Making commits

Use `git commit` normally under your own identity:

```bash
git config --local user.name  # Should show your name
git config --local user.email # Should show your email
git commit -m "message"
```

## Verification

Check that git is using your identity (not Claude's):

```bash
git config --local user.name
git config --local user.email
```

## Reference

- [GitHub Co-authored commits](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors)


