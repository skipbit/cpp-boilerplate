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
#
# What it contains is decided by one question: the published repository is
# where somebody starts developing, not a shelf the template is displayed on.
# So it gets the environment (.devcontainer), the hooks, the release script and
# a full set of workflows, and not only the sources.

set -euo pipefail

# The account the template repositories live under. Override to publish elsewhere.
readonly owner="${CPPBP_OWNER:-skipbit}"

# Copied to the same path. A template that ships its own copy keeps it.
readonly shared=(
    .clang-format
    .clang-tidy
    .clangd
    .devcontainer
    .editorconfig
    .githooks
    .github/actionlint.yaml
    .github/dependabot.yml
    .gitignore
    LICENSE
    docs
    scripts/check-tidy-rationale.sh
    scripts/install-hooks.sh
    scripts/release.sh
)

# ci/<name>.yml becomes .github/workflows/<name>.yml. The monorepo's own
# workflows in .github/workflows/ are not published: they build every template
# together, which is not a thing a single project can do.
readonly workflow_source="ci"

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

# The table in the README is the only index of which templates exist and where
# they went, so a template that is not in it is a template nobody can find.
# Checked here rather than in CI because publishing is the only moment the
# answer can change - and the clean tree above means this README is the one
# that is about to be public, not an uncommitted local edit.
if $push && ! grep -q "github.com/${owner}/${repo}" "$root/README.md"; then
    die "README.md does not link ${owner}/${repo}; add its row to the table, and commit it, first"
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# -L resolves cmake/modules, which is a symlink here and must be real there.
cp -rL "$src/." "$work/"

# The template's own copy wins, so a template can replace a shared file without
# changing it for every other one.
add_shared() {
    local from=$1 to=$2
    [ -e "$work/$to" ] && return 0
    mkdir -p "$(dirname "$work/$to")"
    cp -rL "$from" "$work/$to"
}

for f in "${shared[@]}"; do
    add_shared "$root/$f" "$f"
done

for f in "$root/$workflow_source"/*.yml; do
    add_shared "$f" ".github/workflows/$(basename "$f")"
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
# The tree is assembled in a temporary directory, so neither this repository's
# local configuration nor a conditional include in the global one reaches it.
# Carry over whoever is publishing instead of naming a person here.
git config user.name "$(git -C "$root" config user.name)"
git config user.email "$(git -C "$root" config user.email)"
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

if gh repo view "${owner}/${repo}" > /dev/null 2>&1; then
    # The push below rewrites history, which leaves an open pull request
    # unmergeable against a branch that no longer contains its base - and its
    # author with nothing to read that explains why. The README asks people not
    # to send one; this is what happens when somebody does anyway.
    open_prs=$(gh pr list --repo "${owner}/${repo}" --state open --json number --jq 'length')
    [ "$open_prs" = "0" ] \
        || die "${owner}/${repo} has ${open_prs} open pull request(s); answer them before force-pushing over them"
else
    gh repo create "${owner}/${repo}" --public
fi

# HTTPS deliberately. Over SSH the push is made by whichever key the agent
# offers first, which is not necessarily the account that owns this repository;
# over HTTPS gh's credential helper picks the one that does.
git remote add origin "https://${owner}@github.com/${owner}/${repo}.git"
git push --force --quiet origin main

# Everything about the repository that is not a file, applied on every publish
# rather than once at creation. A setting that only ran inside `gh repo create`
# can never be corrected, and can never reach a repository published before it
# was written - so the second template would silently differ from the first.
#
# Issues are off: this repository is force-pushed from somewhere else, so a
# report filed here is answered by nobody and deleted by the next publish. The
# README says where it goes instead, in its third line.
gh repo edit "${owner}/${repo}" \
    --description "A C++ ${name} template: CMake, CI, sanitizers, static analysis and an installable package. Generated from cpp-boilerplate. 0BSD." \
    --homepage "https://github.com/${owner}/cpp-boilerplate" \
    --enable-issues=false \
    --template
gh api -X PUT "repos/${owner}/${repo}/topics" \
    -f 'names[]=cpp' -f 'names[]=cpp23' -f 'names[]=cmake' \
    -f 'names[]=template' -f 'names[]=project-template' -f "names[]=${name}" > /dev/null

echo "Published https://github.com/${owner}/${repo}"
