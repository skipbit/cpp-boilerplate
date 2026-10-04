#!/usr/bin/env bash
#
# No include names a path with `.` or `..` in it, or an absolute one.
#
#   ./scripts/check-module-includes.sh
#
# A file includes a header by the name its target's include path gives it: its
# own directory plus the directories of the targets it declares, so an
# undeclared `#include "other.hpp"` does not compile. A path with `.` or `..` in
# it reaches a header that include path never offered, and the dependency it
# creates is declared nowhere - yet it links, since everything ends up in the
# same program. The preprocessor resolves a quoted include from the file that
# writes it, before it consults any include path, and an angle-bracket one from
# each include directory, where `..` walks out of that directory. Both were
# measured: `#include <../other/other.hpp>` compiles in a target whose include
# path is only its own directory, which is why the check cannot be narrower
# than both bracket forms.
#
# This is what refuses them, in a second.
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

# An include whose path is absolute or has a `.` or `..` element, after the
# opening quote or angle bracket. Three cases, in the order the pattern has them:
#
#   /                  an absolute path, which names a header by where it sits
#                      on this machine rather than by any include path.
#   \.\.?/             a `.` or `..` element at the start of the path:
#                      `./x.hpp`, `../x/x.hpp`.
#   [^">]*/\.\.?/      a `.` or `..` element after a directory: `a/../b.hpp`,
#                      `./../x.hpp`.
#
# The pattern writes the last two as one optional prefix, `([^">]*/)?`. `./x.hpp`
# is refused though it is harmless; the message says to write the bare name.
climbs='^[[:space:]]*#[[:space:]]*include[[:space:]]*["<](/|([^">]*/)?\.\.?/)'

# Read out of the index, like the list above and like the hook's formatting
# check: a rename that is half staged leaves the working tree with paths the
# index does not have, and grep on those is an error message rather than an
# answer. What is being committed is what this has to judge.
#
# git grep exits 1 for no matches and 2 or more when the search itself failed,
# and the second must not read as the first: a check that cannot search has
# found nothing only in the sense that it did not look.
status=0
offenders=$(git grep --cached -n -E "$climbs" -- "${files[@]}") || status=$?

if [ "$status" -gt 1 ]; then
    echo "error: git grep failed with status $status; this check could not search" >&2
    exit 1
fi

if [ -n "$offenders" ]; then
    printf '%s\n' "$offenders" >&2
    cat >&2 << 'MESSAGE'

error: the includes above name a path with `.` or `..` in it, or an absolute one.

A file includes a header by the name its target's include path gives it. A path
with `.` or `..` in it reaches a header that include path never offered, and
the dependency it creates is declared nowhere. Declare the dependency where the
target is defined, and include the header by its own name. `#include "./x.hpp"`
is refused too: write `#include "x.hpp"`.
MESSAGE
    exit 1
fi
