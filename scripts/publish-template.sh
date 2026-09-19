#!/usr/bin/env bash
#
# Assembles a template into its own repository and publishes it.
#
#   ./scripts/publish-template.sh lib                    # assemble, report, throw away
#   ./scripts/publish-template.sh lib --push             # assemble and publish
#   ./scripts/publish-template.sh lib --assemble-to DIR  # leave the tree in DIR
#   ./scripts/publish-template.sh --all --push           # the same, for every template
#
# --assemble-to hands the tree over without building or committing, which is how
# distribution-check.yml compares it with what is published.
#
# This script is the definition of what a published template contains, and the
# published repository is force-pushed from it.

set -euo pipefail

# The account the template repositories live under. Override to publish elsewhere.
readonly owner="${CPPBP_OWNER:-skipbit}"

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

# ci/<name>.yml becomes .github/workflows/<name>.yml. The workflows in
# .github/workflows/ are this repository's own and are not published.
readonly workflow_source="ci"

readonly disabled_workflow="dependency-freshness.yml"

die() { echo "error: $*" >&2; exit 1; }

usage="usage: $0 <template-name> [--push | --assemble-to <dir>]
       $0 --all [--push]"

all=false
name=""
push=false
assemble_to=""

case "${1:-}" in
    "") die "$usage" ;;
    --all) all=true ;;
    -*) die "unknown argument '${1}'" ;;
    *) name=$1 ;;
esac

case "${2:-}" in
    "") ;;
    --push) push=true ;;
    --assemble-to)
        if $all; then
            die "--all assembles every template; --assemble-to is one directory"
        fi
        assemble_to=${3:-}
        [ -n "$assemble_to" ] || die "--assemble-to needs a directory"
        ;;
    *) die "unknown argument '${2}'" ;;
esac

root=$(cd "$(dirname "$0")/.." && pwd)

# Read from the directory rather than listed here: a list is what a new template
# gets left out of.
names=()
if $all; then
    for dir in "$root/templates"/*/; do
        names+=("$(basename "$dir")")
    done
    [ ${#names[@]} -gt 0 ] || die "no templates under templates/"
else
    names=("$name")
fi

source_commit=$(git -C "$root" rev-parse --short HEAD)
if [ -z "$assemble_to" ] && [ -n "$(git -C "$root" status --porcelain)" ]; then
    die "the working tree is dirty; publish from a committed state so the record means something"
fi

# A publish is none of the triggers distribution-check.yml lists, so it is
# started here. From the exit path, because a run that stops after a push has
# published something and the check is what says so.
#
# Only when this commit is on main: the run is dispatched against the default
# branch, so it would otherwise assemble from an older commit and report this
# repository behind. Never fatal - the publish has already happened.
start_distribution_check() {
    if [ "$(gh api "repos/${owner}/${source_repo}/commits/main" --jq '.sha' 2> /dev/null)" \
        = "$(git -C "$root" rev-parse HEAD)" ]; then
        gh workflow run distribution-check.yml --repo "${owner}/${source_repo}" \
            || echo "warning: could not start the distribution check; start it by hand" >&2
    else
        echo "note: this commit is not on ${source_repo} main yet; pushing it starts the check" >&2
    fi
}

workroot=$(mktemp -d)
pushed=false
cleanup() {
    rm -rf "$workroot"
    if $pushed; then
        start_distribution_check
    fi
}
trap cleanup EXIT

# The template's own copy wins, per file. A directory is merged rather than
# taken whole, so a template that ships only .devcontainer/Dockerfile still gets
# the devcontainer.json beside it.
add_shared() {
    local from=$1 to=$2
    if [ -d "$from" ]; then
        local entry
        while IFS= read -r entry; do
            add_shared "$from/$entry" "$to/$entry"
        done < <(find "$from" -mindepth 1 ! -type d -printf '%P\n' | sort)
        return 0
    fi
    [ -e "$work/$to" ] && return 0
    mkdir -p "$(dirname "$work/$to")"
    cp -L "$from" "$work/$to"
}

publish_template() {
    local name=$1
    local src="$root/templates/$name"
    [ -d "$src" ] || die "no template at templates/$name"

    local repo="${source_repo}-$name"

    if $push && ! grep -q "github.com/${owner}/${repo}" "$root/README.md"; then
        die "README.md does not link ${owner}/${repo}; add its row to the table, and commit it, first"
    fi

    work="$workroot/$name"
    mkdir -p "$work"

    # -L resolves cmake/modules, which is a symlink here and must be real there.
    cp -rL "$src/." "$work/"

    local f
    for f in "${shared[@]}"; do
        add_shared "$root/$f" "$f"
    done

    for f in "$root/$workflow_source"/*.yml; do
        add_shared "$f" ".github/workflows/$(basename "$f")"
    done

    # Before the build, so what is compared with what is published is the same
    # set of files and nothing derived from it.
    if [ -n "$assemble_to" ]; then
        mkdir -p "$assemble_to"
        cp -a "$work/." "$assemble_to/"
        echo "Assembled ${repo} from ${source_repo}@${source_commit} into ${assemble_to}"
        return 0
    fi

    cd "$work"

    # Build what was assembled, not what it was assembled from: a missing shared
    # file shows up here and nowhere else.
    if command -v cmake > /dev/null 2>&1; then
        echo "Verifying the assembled ${name} tree..."
        local verify="$work/.verify"
        cmake -S . -B "$verify" -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null \
            || die "the assembled tree does not configure"
        cmake --build "$verify" > /dev/null \
            || die "the assembled tree does not build"
        # --no-tests=error: a tree that arrived without its tests is what this
        # step is here to catch, and ctest calls finding none of them a success.
        ctest --test-dir "$verify" --output-on-failure --no-tests=error > /dev/null \
            || die "the assembled tree does not pass its tests, or has none to run"
        rm -rf "$verify"
        echo "  configures, builds, tests."
    else
        echo "warning: cmake not found; publishing without verifying" >&2
    fi

    git init -q -b main
    # A repository in a temporary directory inherits no user configuration, so
    # the one publishing is carried over rather than named here.
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
        return 0
    fi

    if gh repo view "${owner}/${repo}" > /dev/null 2>&1; then
        # The push below rewrites history, which leaves an open pull request
        # unmergeable against a branch that no longer contains its base.
        local open_prs
        open_prs=$(gh pr list --repo "${owner}/${repo}" --state open --json number --jq 'length')
        [ "$open_prs" = "0" ] \
            || die "${owner}/${repo} has ${open_prs} open pull request(s); answer them before force-pushing over them"
    else
        gh repo create "${owner}/${repo}" --public
    fi

    # HTTPS deliberately: over SSH the push is made by whichever key the agent
    # offers first, which is not necessarily the account that owns this one.
    git remote add origin "https://${owner}@github.com/${owner}/${repo}.git"
    git push --force --quiet origin main
    pushed=true

    # Applied on every publish rather than at creation, so a setting written
    # later reaches the repositories published before it. Issues are off because
    # a report filed on a generated repository is deleted by the next publish.
    gh repo edit "${owner}/${repo}" \
        --description "A C++ ${name} template: CMake, CI, sanitizers, static analysis and tests, working from the first commit. Generated from ${source_repo}. 0BSD." \
        --homepage "https://github.com/${owner}/${source_repo}" \
        --enable-issues=false \
        --template
    gh api -X PUT "repos/${owner}/${repo}/topics" \
        -f 'names[]=cpp' -f 'names[]=cpp23' -f 'names[]=cmake' \
        -f 'names[]=template' -f 'names[]=project-template' -f "names[]=${name}" > /dev/null

    # Switched off as a repository setting rather than as a condition in the
    # file, which would switch it off in everybody's project too. The state is
    # read before it is set, because disabling an already disabled workflow
    # answers 403. The wait is for the first publish: a workflow does not exist
    # to the API until GitHub has processed the push that introduced it.
    local workflow_api="repos/${owner}/${repo}/actions/workflows/${disabled_workflow}"
    local workflow_state=""
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
}

for name in "${names[@]}"; do
    publish_template "$name"
done
