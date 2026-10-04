#!/usr/bin/env bash
#
# No file reaches out of its own directory with a quoted include.
#
#   ./scripts/check-module-includes.sh
#
# src/<module>/ is a target whose include path is its own directory plus the
# directories of the modules it declares, so an undeclared `#include "other.hpp"`
# does not compile. The preprocessor resolves a quoted include relative to the
# file that writes it before it consults any include path at all, though, so
# `#include "../other/other.hpp"` reaches past all of that - and it links, since
# every module ends up in the same program.
#
# That is the one way a declared dependency graph can be wrong and still build.
# This is what says so, in a second.
#
# The file list comes from scripts/lint-paths.sh, which .githooks/pre-commit
# asks the same question of, so the hook cannot check an extension this does not.

set -euo pipefail

cd "$(dirname "$0")/.."

mapfile -t files < <(./scripts/lint-paths.sh module-includes)

# Matching nothing is a failure, not a pass. A check with no work to do reports
# the same thing as one that found none.
if [ ${#files[@]} -eq 0 ]; then
    echo "error: no files matched; this check would have passed by finding nothing" >&2
    exit 1
fi

# Read out of the index, like the list above and like the hook's formatting
# check: a rename that is half staged leaves the working tree with paths the
# index does not have, and grep on those is an error message rather than an
# answer. What is being committed is what this has to judge.
offenders=$(git grep --cached -n -E '^[[:space:]]*#[[:space:]]*include[[:space:]]*"\.\./' -- "${files[@]}" || true)

if [ -n "$offenders" ]; then
    printf '%s\n' "$offenders" >&2
    cat >&2 << 'MESSAGE'

error: the includes above climb out of their own directory.

A module may use another one only by declaring it in src/CMakeLists.txt, which
puts that module's directory on the include path and lets the header be included
by its own name. A relative path gets there without declaring anything, and the
graph in src/CMakeLists.txt stops being the truth.
MESSAGE
    exit 1
fi
