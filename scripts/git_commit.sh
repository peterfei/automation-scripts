#!/bin/bash

# Automated Git commit script
# Usage: ./git_commit.sh <commit_message>

COMMIT_MSG=$1

if [ -z "$COMMIT_MSG" ]; then
    echo "Usage: $0 <commit_message>"
    exit 1
fi

if [ ! -d ".git" ]; then
    echo "Not a Git repository."
    exit 1
fi

git add .
git commit -m "$COMMIT_MSG"
git push

echo "Committed and pushed with message: $COMMIT_MSG"
