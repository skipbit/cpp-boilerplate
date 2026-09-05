#!/usr/bin/env bash
#
# Assembles a template into its own repository and publishes it.
#
#   ./scripts/publish-template.sh lib                    # assemble, report, throw away
#   ./scripts/publish-template.sh lib --push             # assemble and publish
#   ./scripts/publish-template.sh lib --assemble-to DIR  # leave the tree in DIR
#
# --assemble-to stops after assembling: no build, no commit, no push. It exists
# so that something else can look at the tree - distribution-check.yml compares
# it with what is actually published - without that comparison growing its own
# copy of the rules below, which is how the two would come to disagree.
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

# This repository. Each published repository is named after it, so is the
# homepage they are given, and so is the check that compares the two - one
# string here, or three elsewhere that can drift apart.
readonly source_repo="cpp-boilerplate"

# Copied to the same path. A template that ships its own copy keeps it.
readonly shared=(
    .clang-format
    .clang-tidy
    .clangd
    .devcontainer
    .editorconfig
    .githooks
    .github/actionlint.yml
    .github/dependabot.yml
    .gitignore
    .hadolint.yaml
    LICENSE
    docs
    scripts/check-tidy-rationale.sh
    scripts/install-hooks.sh
    scripts/lint-paths.sh
    scripts/release.sh
)

# ci/<name>.yml becomes .github/workflows/<name>.yml. The monorepo's own
# workflows in .github/workflows/ are not published: they build every template
# together, which is not a thing a single project can do.
readonly workflow_source="ci"

die() { echo "error: $*" >&2; exit 1; }

name=${1:-}
[ -n "$name" ] || die "usage: $0 <template-name> [--push | --assemble-to <dir>]"
push=false
assemble_to=""
case "${2:-}" in
    "") ;;
    --push) push=true ;;
    --assemble-to)
        assemble_to=${3:-}
        [ -n "$assemble_to" ] || die "--assemble-to needs a directory"
        ;;
    *) die "unknown argument '${2}'" ;;
esac

root=$(cd "$(dirname "$0")/.." && pwd)
src="$root/templates/$name"
[ -d "$src" ] || die "no template at templates/$name"

repo="${source_repo}-$name"
source_commit=$(git -C "$root" rev-parse --short HEAD)
# Not required for --assemble-to: nothing is recorded and nothing is published,
# so there is no claim for a dirty tree to make false.
if [ -z "$assemble_to" ] && [ -n "$(git -C "$root" status --porcelain)" ]; then
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

# Handing over the tree is the whole job in this mode. Deliberately before the
# build below: what is published is a set of files, so what gets compared with
# what is published is that same set of files and nothing derived from it.
if [ -n "$assemble_to" ]; then
    mkdir -p "$assemble_to"
    cp -a "$work/." "$assemble_to/"
    echo "Assembled ${repo} from ${source_repo}@${source_commit} into ${assemble_to}"
    exit 0
fi

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
    # --no-tests=error, because a tree that arrived without its tests is the
    # failure this step is here to catch, and ctest calls finding none of them
    # a success. The message says both: from here the two are one answer, which
    # is that what was about to be published is not what was checked.
    ctest --test-dir "$verify" --output-on-failure --no-tests=error > /dev/null \
        || die "the assembled tree does not pass its tests, or has none to run"
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

Assembled from ${source_repo}@${source_commit}. This repository is generated:
changes belong in the source, not here."

echo "Assembled ${repo} from ${source_repo}@${source_commit}:"
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

# distribution-check.yml says why it is red. What it cannot see is the publish
# that makes it green, a publish being none of the triggers it lists, so the
# red outlives the fact it reports for as long as it takes somebody to remember
# to start it by hand.
#
# Started here rather than at the end because the template is live from the
# push above, and everything below can still die - a repository setting, a
# workflow GitHub has not caught up with. None of that makes what was published
# any less published, or the stale red any less worth clearing.
#
# Started on every publish rather than on the last one, because this script
# publishes a single template and cannot know which one is last. The runs in
# between are red, and right to be.
#
# Only when this commit is the one the check will read. The run is dispatched
# against the source repository's default branch, so publishing ahead of the
# push - the order CONTRIBUTING gives for a template being added - would have
# it assemble from an older main and report this repository behind, which is
# false and cannot be acted on. That push starts the check by itself.
#
# Not fatal either way: the publish has already happened, and a check that was
# not started is a smaller thing to be wrong than a publish reported as failed.
if [ "$(gh api "repos/${owner}/${source_repo}/commits/main" --jq '.sha' 2> /dev/null)" \
    = "$(git -C "$root" rev-parse HEAD)" ]; then
    gh workflow run distribution-check.yml --repo "${owner}/${source_repo}" \
        || echo "warning: could not start the distribution check; start it by hand" >&2
else
    echo "note: this commit is not on ${source_repo} main yet; pushing it starts the check" >&2
fi

# Everything about the repository that is not a file, applied on every publish
# rather than once at creation. A setting that only ran inside `gh repo create`
# can never be corrected, and can never reach a repository published before it
# was written - so the second template would silently differ from the first.
#
# Issues are off: this repository is force-pushed from somewhere else, so a
# report filed here is answered by nobody and deleted by the next publish. The
# README says where it goes instead, in its third line.
gh repo edit "${owner}/${repo}" \
    --description "A C++ ${name} template: CMake, CI, sanitizers, static analysis and tests, working from the first commit. Generated from ${source_repo}. 0BSD." \
    --homepage "https://github.com/${owner}/${source_repo}" \
    --enable-issues=false \
    --template
gh api -X PUT "repos/${owner}/${repo}/topics" \
    -f 'names[]=cpp' -f 'names[]=cpp23' -f 'names[]=cmake' \
    -f 'names[]=template' -f 'names[]=project-template' -f "names[]=${name}" > /dev/null

# dependency-freshness is shipped to whoever uses the template and switched off
# here. This repository has nothing for it to find: its pins are copied from the
# source on every publish, so the place to fix one is never here - and its issue
# tracker is closed, so the job's only way of reporting would fail and leave a
# weekly red cross on a repository whose whole job is to look like a safe place
# to start. Switched off as a repository setting rather than as a condition in
# the file, because a condition would be copied into everybody's project and
# switch it off there too, which is the one place it is worth having.
#
# The state is read before it is set, because disabling one that is already
# disabled answers 403 rather than doing nothing, and every publish after the
# first would fail on it. It is read again afterwards, because a publish that
# quietly failed here would be discovered by the cross it exists to prevent.
# The wait is for the first publish: a workflow does not exist to the API until
# GitHub has processed the push that introduced it.
readonly disabled_workflow="dependency-freshness.yml"
readonly workflow_api="repos/${owner}/${repo}/actions/workflows/${disabled_workflow}"

workflow_state=""
for _ in 1 2 3 4 5; do
    workflow_state=$(gh api "$workflow_api" --jq '.state' 2> /dev/null) || workflow_state=""
    if [ -n "$workflow_state" ]; then
        break
    fi
    sleep 3
done
[ -n "$workflow_state" ] \
    || die "${owner}/${repo} has no ${disabled_workflow} yet; run this again once GitHub has caught up"

if [ "$workflow_state" = "active" ]; then
    gh workflow disable "$disabled_workflow" --repo "${owner}/${repo}"
    workflow_state=$(gh api "$workflow_api" --jq '.state')
fi

[ "$workflow_state" = "disabled_manually" ] \
    || die "${disabled_workflow} is ${workflow_state} on ${owner}/${repo}; it will run on a closed issue tracker and fail"

echo "Published https://github.com/${owner}/${repo}"

