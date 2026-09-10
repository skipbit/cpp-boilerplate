#!/usr/bin/env bash
#
# An action used by the workflows here is pinned to one version, in every file
# that uses it.
#
#   ./scripts/check-workflow-pins.sh
#
# There are two sets of workflows. .github/workflows/ is what this repository
# runs; ci/ is what a published template runs, and they name the same actions.
# Dependabot reads the first set only - github-actions with directory / means
# .github/workflows and nothing else - so a bump it proposes lands there and
# leaves ci/ behind.
#
# What notices then is Dependabot in each published repository, where a pull
# request cannot be merged without putting that repository ahead of this one,
# and cannot be left open without stopping the next publish. It cannot be
# switched off there either: the API answers 422 and the interface offers
# nothing. So the way to keep it quiet is to give it nothing to say.
#
# This is a monorepo check. A published template has one set of workflows and
# nothing to compare.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# owner/name@ref. A local reusable workflow is ./path and pins nothing.
mapfile -t pins < <(
    git ls-files -- '.github/workflows/*.yml' 'ci/*.yml' \
        | xargs grep -hoE 'uses: [^ ./][^@[:space:]]*@[^[:space:]]+' \
        | sed 's/^uses: //' \
        | sort -u
)

# Nothing found is a broken check, not a clean repository: these workflows have
# used actions since the first commit.
[ ${#pins[@]} -gt 0 ] || {
    echo "error: no 'uses: owner/name@version' found in any workflow" >&2
    exit 1
}

mapfile -t conflicting < <(printf '%s\n' "${pins[@]}" | sed 's/@.*//' | sort | uniq -d)

if [ ${#conflicting[@]} -gt 0 ]; then
    for action in "${conflicting[@]}"; do
        echo "--- ${action} ---" >&2
        for pin in "${pins[@]}"; do
            [ "${pin%@*}" = "$action" ] || continue
            printf '  %s\n' "$pin" >&2
            git grep -l -- "uses: ${pin}" -- '.github/workflows/*.yml' 'ci/*.yml' \
                | sed 's/^/    /' >&2
        done
    done
    echo >&2
    echo "error: these are pinned to more than one version:" >&2
    printf '  %s\n' "${conflicting[@]}" >&2
    echo >&2
    echo "Bump them together. ci/ is what the published templates run, and" >&2
    echo "nothing here proposes a version for it." >&2
    exit 1
fi

echo "${#pins[@]} action(s), one version each:"
printf '  %s\n' "${pins[@]}"
