#!/usr/bin/env bash
#
# Every .devcontainer/Dockerfile in this repository has to pin the same
# toolchain, and to carry the same archive signing keys beside it.
#
#   ./scripts/check-toolchain-pins.sh
#
# A template that needs a system library gets its own image, and there is no way
# to write "the shared one, plus Qt" in a Dockerfile that also has to build from
# a published repository's own files. So the toolchain is copied, and a copy
# drifts - the shared file gets a new clang and the other one does not, and the
# job that was meant to prove the environment is fixed proves it for some
# templates only.
#
# The keys are part of that copy. They are what apt verifies the pinned packages
# against, so one left behind is an archive that stops being readable on the day
# it is replaced upstream.
#
# This is a monorepo check. It is not shipped with a template, because a
# published template has exactly one of these files and nothing to compare.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

readonly shared=.devcontainer/Dockerfile
readonly shared_dir=.devcontainer
[ -f "$shared" ] || { echo "error: no $shared" >&2; exit 1; }

pins() { grep -E '^ARG [A-Z_]+=' "$1" | sort; }

# Taken from what is beside the shared Dockerfile rather than listed here, so a
# third key added there is compared without this script being edited.
keys=()
while IFS= read -r path; do
    keys+=("${path##*/}")
done < <(git ls-files -- "${shared_dir}/*-keyring.asc" | sort)

# Matching nothing is a failure, not a pass: this half of the check would report
# success by having nothing to compare.
if [ ${#keys[@]} -eq 0 ]; then
    echo "error: no *-keyring.asc beside ${shared}; this check would have passed by finding none" >&2
    exit 1
fi

expected=$(pins "$shared")
differing=()

while read -r file; do
    [ "$file" = "$shared" ] && continue
    if [ "$(pins "$file")" != "$expected" ]; then
        differing+=("$file")
        echo "--- ${file} against ${shared} ---" >&2
        diff <(echo "$expected") <(pins "$file") >&2 || true
    fi
    for key in "${keys[@]}"; do
        to="$(dirname "$file")/${key}"
        if [ ! -f "$to" ]; then
            differing+=("$to")
            echo "--- ${to} is missing, and ${shared_dir}/${key} is there ---" >&2
        elif ! cmp -s "${shared_dir}/${key}" "$to"; then
            differing+=("$to")
            echo "--- ${to} is not a copy of ${shared_dir}/${key} ---" >&2
        fi
    done
done < <(git ls-files -- '*.devcontainer/Dockerfile' | sort)

if [ ${#differing[@]} -gt 0 ]; then
    echo >&2
    echo "error: these disagree with what ${shared} pins and verifies:" >&2
    printf '  %s\n' "${differing[@]}" >&2
    echo >&2
    echo "Bump or copy them together, or say in ${shared} why one of them is" >&2
    echo "deliberately behind. A copy nobody compares is a copy that stops being" >&2
    echo "one." >&2
    exit 1
fi

echo "Every .devcontainer/Dockerfile pins the toolchain and carries the keys in ${shared_dir}."
