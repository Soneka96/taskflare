#!/usr/bin/env bash
set -e

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//')
TAG="v$VERSION"

echo "Releasing $TAG..."

git checkout main
git merge dev
git push origin main
git tag "$TAG"
git push origin "$TAG"

echo "Done — $TAG pushed. GitHub Actions will publish to pub.dev."
