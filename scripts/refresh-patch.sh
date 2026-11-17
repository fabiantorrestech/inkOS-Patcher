#!/usr/bin/env bash
# Moves one patch onto a new inkOS release and re-exports patches/<name>.patch.
#
# Usage:  scripts/refresh-patch.sh <path to inkOS checkout> <release tag, e.g. v0.7> [patch name]
#
# Patch names: hide-until-search (default), page-indicator-options.
# Each patch lives as ONE commit on branch patch/<name> in the local inkOS clone.
# If the rebase stops on a conflict: fix the files, `git add` them, `git rebase --continue`,
# then run this script again with the same arguments.
set -euo pipefail

INKOS="${1:?path to inkOS checkout}"
TAG="${2:?release tag, e.g. v0.7}"
NAME="${3:-hide-until-search}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM="https://github.com/gezimos/inkOS"
BRANCH="patch/$NAME"

cd "$INKOS"

if [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
  echo "A rebase is still in progress in $INKOS. Finish it first (git rebase --continue)." >&2
  exit 1
fi
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "$INKOS has uncommitted changes. Commit or stash them first." >&2
  exit 1
fi

git fetch --quiet "$UPSTREAM" "refs/tags/$TAG:refs/tags/$TAG"
git switch --quiet "$BRANCH"

if [ "$(git rev-parse HEAD~1)" != "$(git rev-parse "refs/tags/$TAG^{commit}")" ]; then
  echo "Rebasing $BRANCH onto inkOS $TAG..."
  git rebase --onto "refs/tags/$TAG" HEAD~1 "$BRANCH"
fi

if [ "$(git rev-list --count "refs/tags/$TAG..HEAD")" != "1" ]; then
  echo "$BRANCH should be exactly one commit on top of $TAG. Squash it first." >&2
  exit 1
fi

echo "Building the debug APK..."
./gradlew -q assembleDebug

git format-patch -1 HEAD --stdout > "$HERE/patches/$NAME.patch"
echo "Updated $HERE/patches/$NAME.patch"
echo
echo "Next:"
echo "  1. Commit and push patches/$NAME.patch in $HERE"
echo "  2. Run the 'Build patched inkOS' workflow with release $TAG"
