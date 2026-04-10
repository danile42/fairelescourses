#!/bin/bash
# Commit script for GitHub Copilot - signs commits with Copilot as co-author
# Usage: ./.claude/scripts/commit-as-copilot.sh "commit message"

if [ -z "$1" ]; then
  echo "Usage: $0 \"commit message\""
  exit 1
fi

commit_message="$1"

# Add co-author trailer
message_with_coauthor=$(printf "%s\n\nCo-authored-by: GitHub Copilot <copilot-agent@users.noreply.github.com>" "$commit_message")

# Commit with the co-author trailer
git commit -m "$message_with_coauthor"


