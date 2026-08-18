#!/usr/bin/env bash
#
# Assembles a template into its own repository and publishes it.
#
#   ./scripts/publish-template.sh lib            # assemble, report, throw away
#   ./scripts/publish-template.sh lib --push     # assemble and publish
#
# The published repository is a build product, not a fork: it is force-pushed
# from what is here. A template directory alone is not enough to publish -
# it needs the license and the linting configuration that every template
# shares, and the shared CMake modules it reaches through a symlink - so this
# script is the definition of what a published template actually contains.

set -euo pipefail

readonly owner="skipbit"
readonly shared=(.clang-format .clang-tidy .editorconfig .gitignore LICENSE)

die() { echo "error: $*" >&2; exit 1; }

name=${1:-}
[ -n "$name" ] || die "usage: $0 <template-name> [--push]"
push=false
[ "${2:-}" = "--push" ] && push=true

root=$(cd "$(dirname "$0")/.." && pwd)
src="$root/templates/$name"
[ -d "$src" ] || die "no template at templates/$name"

repo="cpp-boilerplate-$name"
source_commit=$(git -C "$root" rev-parse --short HEAD)
if [ -n "$(git -C "$root" status --porcelain)" ]; then
    die "the working tree is dirty; publish from a committed state so the record means something"
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# -L resolves cmake/modules, which is a symlink here and must be real there.
cp -rL "$src/." "$work/"
for f in "${shared[@]}"; do
    cp "$root/$f" "$work/$f"
done

cd "$work"

# Build what was assembled, not what it was assembled from. A template that
# only builds inside the monorepo is exactly the failure this script can
# introduce: a missing shared file shows up here and nowhere else.
if command -v cmake > /dev/null 2>&1; then
    echo "Verifying the assembled tree..."
    verify="$work/.verify"
    cmake -S . -B "$verify" -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null \
        || die "the assembled tree does not configure"
    cmake --build "$verify" > /dev/null \
        || die "the assembled tree does not build"
    ctest --test-dir "$verify" --output-on-failure > /dev/null \
        || die "the assembled tree does not pass its tests"
    rm -rf "$verify"
    echo "  configures, builds, tests."
else
    echo "warning: cmake not found; publishing without verifying" >&2
fi

git init -q -b main
git config user.name "Yuma Endo"
git config user.email "endo@skipbit.jp"
git add -A
git commit -q -m "Publish the ${name} template

Assembled from cpp-boilerplate@${source_commit}. This repository is generated:
changes belong in the source, not here."

echo "Assembled ${repo} from cpp-boilerplate@${source_commit}:"
git -c core.pager=cat ls-files | sed 's/^/  /'
echo

if ! $push; then
    echo "Not pushed. Pass --push to publish."
    exit 0
fi

if ! gh repo view "${owner}/${repo}" > /dev/null 2>&1; then
    gh repo create "${owner}/${repo}" --public \
        --description "A C++ ${name} template: CMake, CI, sanitizers, static analysis and an installable package. Generated from cpp-boilerplate. 0BSD."
fi

# HTTPS deliberately: the ssh key on this machine belongs to a different
# account, and gh's credential helper uses the one that owns the repository.
git remote add origin "https://${owner}@github.com/${owner}/${repo}.git"
git push --force --quiet origin main

gh repo edit "${owner}/${repo}" --template
gh api -X PUT "repos/${owner}/${repo}/topics" \
    -f 'names[]=cpp' -f 'names[]=cpp23' -f 'names[]=cmake' \
    -f 'names[]=template' -f 'names[]=project-template' -f "names[]=${name}" > /dev/null

echo "Published https://github.com/${owner}/${repo}"
