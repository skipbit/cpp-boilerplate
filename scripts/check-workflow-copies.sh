#!/usr/bin/env bash
#
# A workflow that ci/ and .github/workflows/ both carry is the same file in
# both, outside its comments.
#
#   ./scripts/check-workflow-copies.sh
#
# There are two sets of workflows. .github/workflows/ is what this repository
# runs; ci/ is published into each template as its .github/workflows/. Some
# files in the two are meant to be one file, and they are kept so by hand: an
# edit to one is an edit somebody has to remember to make to the other, and
# nothing else says when it was not made.
#
# A comment on a line of its own may differ, and this repository has one that
# does: the schedule in dependency-freshness.yml is annotated in Japan time
# here and in UTC in the published copy, because whoever starts from the
# template is not in Japan. A comment at the end of a line is part of that
# line and has to agree - which is why that annotation sits on a line of its
# own.
#
# The same rule removes a line that begins with # inside a run: block, where it
# is shell rather than YAML. None of the files compared here writes one into
# anything it generates; a Markdown heading in an issue body would be the way
# that happens, and it would compare equal on both sides.
#
# Every pair is named below, as one that has to agree or one that is a
# different file by design, and each list is checked against what is there. A
# pair cannot be added, removed or renamed without this saying so - which is
# the point, because a pair that quietly stops being compared is a check that
# passes by having less to do.
#
# This is a monorepo check. A published template has one set of workflows and
# nothing to compare.

set -euo pipefail

# Assigned and then used: `cd "$(git rev-parse ...)"` outside a work tree is
# `cd ""`, which succeeds and leaves the script running wherever it was called.
root=$(git rev-parse --show-toplevel)
cd "$root"

# Asked of each list below, so it is one function rather than one idiom here
# and another one there.
contains() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

# Pairs that have to agree.
readonly required=(dependency-freshness.yml main-check.yml pr-check.yml)

# Pairs that are different files by design, with why.
#   build-and-test.yml    this repository builds every template and a published
#                         one builds a single project
#   nightly-sanitizer.yml a different image tag
#   preset-check.yml      this repository walks the presets of every template
readonly different=(build-and-test.yml nightly-sanitizer.yml preset-check.yml)

# Read out of the index, like the repository's other checks: a file that is
# staged is already in the answer, and a generated copy cannot get in.
mapfile -t ours < <(git ls-files -- '.github/workflows/*.yml')
pairs=()
while IFS= read -r path; do
    name="${path##*/}"
    if contains ".github/workflows/${name}" "${ours[@]}"; then
        pairs+=("$name")
    fi
done < <(git ls-files -- 'ci/*.yml')

# Matching nothing is a failure, not a pass. An empty list leaves a check that
# reports success by having had nothing to compare.
if [ ${#pairs[@]} -eq 0 ]; then
    echo "error: no file is in both ci/ and .github/workflows/; this would have passed by finding nothing to compare" >&2
    exit 1
fi

# The three questions that keep the lists and the files in step: a name that
# outlived its pair, either way round, and a pair that is in neither list.
for name in "${required[@]}"; do
    contains "$name" "${pairs[@]}" || {
        echo "error: ${name} is named here as a pair that has to agree, and is no longer in both ci/ and .github/workflows/" >&2
        exit 1
    }
done

for name in "${different[@]}"; do
    contains "$name" "${pairs[@]}" || {
        echo "error: ${name} is named here as different on purpose, and is no longer in both ci/ and .github/workflows/; the list has outlived the file" >&2
        exit 1
    }
done

for name in "${pairs[@]}"; do
    contains "$name" "${required[@]}" || contains "$name" "${different[@]}" || {
        echo "error: ${name} is in both ci/ and .github/workflows/ and is in neither list in this script; say which of the two it is" >&2
        exit 1
    }
done

# Comments and blank lines are not code; trailing whitespace is not either.
strip() { sed -E '/^[[:space:]]*#/d; /^[[:space:]]*$/d; s/[[:space:]]+$//' "$1"; }

# Every pair is looked at before anything is reported, so that one missing file
# does not hide the drift in the next one.
failed=0
for name in "${required[@]}"; do
    unreadable=0
    for path in "ci/${name}" ".github/workflows/${name}"; do
        if [ ! -f "$path" ]; then
            echo "error: ${path} is in the index and not on disk" >&2
            unreadable=1
        elif [ -z "$(strip "$path")" ]; then
            echo "error: ${path} has no code once comments and blank lines are removed; this would have passed by comparing nothing" >&2
            unreadable=1
        fi
    done
    if [ "$unreadable" -ne 0 ]; then
        failed=1
        continue
    fi

    if ! diff -u --label "ci/${name}" --label ".github/workflows/${name}" \
        <(strip "ci/${name}") <(strip ".github/workflows/${name}") >&2; then
        echo "error: ci/${name} and .github/workflows/${name} differ in code" >&2
        failed=1
    fi
done

if [ "$failed" -ne 0 ]; then
    echo >&2
    echo "Make the same change in both. Only a comment on a line of its own may differ." >&2
    exit 1
fi

# Printed rather than left to a green tick: a check that says what it compared
# is one somebody can tell from a check that compared nothing.
echo "${#required[@]} workflow(s) the same in ci/ and .github/workflows/, comments aside:"
printf '  %s\n' "${required[@]}"
echo "${#different[@]} different on purpose, not compared:"
printf '  %s\n' "${different[@]}"
