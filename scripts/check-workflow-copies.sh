#!/usr/bin/env bash
#
# A workflow that ci/ and .github/workflows/ both carry is the same file in
# both, comments aside.
#
#   ./scripts/check-workflow-copies.sh
#
# There are two sets of workflows. .github/workflows/ is what this repository
# runs; ci/ is published into each template as its .github/workflows/. Some
# files in the two are meant to be one file, and they are kept so by hand: an
# edit to one is an edit somebody has to remember to make to the other, and
# nothing else says when it was not made.
#
# Comments are allowed to differ and code is not. This repository annotates a
# schedule in Japan time and names its own image tag in a note, while the
# published copy is addressed to whoever started from the template. What the
# job does is the part that has to agree.
#
# A few pairs differ in code on purpose, and are named below with the reason.
# They are not compared, and the list is checked in turn, so a name stays there
# only while the pair exists.
#
# This is a monorepo check. A published template has one set of workflows and
# nothing to compare.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Pairs that are different files by design, with why.
#   build-and-test.yml    this repository builds every template and a published
#                         one builds a single project
#   nightly-sanitizer.yml the image tag and the schedule annotation differ
#   preset-check.yml      this repository walks the presets of every template
readonly different=(build-and-test.yml nightly-sanitizer.yml preset-check.yml)

# Comments and blank lines are not code; trailing whitespace is not either.
strip() { sed -E '/^[[:space:]]*#/d; /^[[:space:]]*$/d; s/[[:space:]]+$//' "$1"; }

pairs=()
while IFS= read -r path; do
    name="${path##*/}"
    if git ls-files --error-unmatch -- ".github/workflows/${name}" > /dev/null 2>&1; then
        pairs+=("$name")
    fi
done < <(git ls-files -- 'ci/*.yml' | sort)

# Matching nothing is a failure, not a pass. An empty list leaves a check that
# reports success by having had nothing to compare.
if [ ${#pairs[@]} -eq 0 ]; then
    echo "error: no file is in both ci/ and .github/workflows/; this would have passed by finding nothing to compare" >&2
    exit 1
fi

# Asked of both lists below, so it is one function rather than one idiom here
# and another one there.
contains() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

for name in "${different[@]}"; do
    contains "$name" "${pairs[@]}" || {
        echo "error: ${name} is listed as different on purpose but is no longer in both ci/ and .github/workflows/; the list has outlived the file" >&2
        exit 1
    }
done

compared=()
skipped=()
failed=0
for name in "${pairs[@]}"; do
    if contains "$name" "${different[@]}"; then
        skipped+=("$name")
        continue
    fi

    # The names come out of the index and the comparison reads the working
    # tree. A file staged for removal would otherwise look like a difference.
    for path in "ci/${name}" ".github/workflows/${name}"; do
        [ -f "$path" ] || {
            echo "error: ${path} is in the index and not on disk" >&2
            exit 1
        }
        # Comparing nothing with nothing passes.
        [ -n "$(strip "$path")" ] || {
            echo "error: ${path} has no code once comments and blank lines are removed; this would have passed by comparing nothing" >&2
            exit 1
        }
    done

    if ! diff -u --label "ci/${name}" --label ".github/workflows/${name}" \
        <(strip "ci/${name}") <(strip ".github/workflows/${name}") >&2; then
        echo "error: ci/${name} and .github/workflows/${name} differ in code" >&2
        failed=1
        continue
    fi
    compared+=("$name")
done

if [ "$failed" -ne 0 ]; then
    echo >&2
    echo "Make the same change in both. Only comments may differ." >&2
    exit 1
fi

# Printed, rather than left to a green tick: a check that says what it compared
# is one somebody can tell from one that compared nothing.
echo "${#compared[@]} workflow(s) the same in ci/ and .github/workflows/, comments aside:"
[ ${#compared[@]} -eq 0 ] || printf '  %s\n' "${compared[@]}"
echo "${#skipped[@]} different on purpose, not compared:"
[ ${#skipped[@]} -eq 0 ] || printf '  %s\n' "${skipped[@]}"
