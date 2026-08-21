#!/usr/bin/env bash
#
# Every .devcontainer/Dockerfile in this repository has to pin the same
# toolchain.
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
# This is a monorepo check. It is not shipped with a template, because a
# published template has exactly one of these files and nothing to compare.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

readonly shared=.devcontainer/Dockerfile
[ -f "$shared" ] || { echo "error: no $shared" >&2; exit 1; }

pins() { grep -E '^ARG [A-Z_]+=' "$1" | sort; }

expected=$(pins "$shared")
differing=()

while read -r file; do
    [ "$file" = "$shared" ] && continue
    if [ "$(pins "$file")" != "$expected" ]; then
        differing+=("$file")
        echo "--- ${file} against ${shared} ---" >&2
        diff <(echo "$expected") <(pins "$file") >&2 || true
    fi
done < <(git ls-files -- '*.devcontainer/Dockerfile' | sort)

if [ ${#differing[@]} -gt 0 ]; then
    echo >&2
    echo "error: these pin a different toolchain from ${shared}:" >&2
    printf '  %s\n' "${differing[@]}" >&2
    echo >&2
    echo "Bump them together, or say in ${shared} why one of them is deliberately" >&2
    echo "behind. A copy nobody compares is a copy that stops being one." >&2
    exit 1
fi

echo "Every .devcontainer/Dockerfile pins the toolchain in ${shared}."
