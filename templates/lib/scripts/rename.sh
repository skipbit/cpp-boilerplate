#!/usr/bin/env bash
#
# Renames the library. Run once, when this becomes your project:
#
#   ./scripts/rename.sh yourlib
#
# Covers the namespace, the target, the installed package, the generated
# headers, the include directory and the naming rule in .clang-tidy. The
# uppercase form (export macros, CMake options) follows automatically.

set -euo pipefail

readonly old="mylib"
readonly OLD="MYLIB"

usage() {
    echo "usage: $0 <new-name>" >&2
    echo "  new-name: lowercase, starting with a letter, e.g. audiokit" >&2
    exit 2
}

[ $# -eq 1 ] || usage
new="$1"

if ! [[ "$new" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "error: '$new' must be lowercase and start with a letter" >&2
    usage
fi

if [ "$new" = "$old" ]; then
    echo "error: that is already the name" >&2
    exit 1
fi

NEW=$(printf '%s' "$new" | tr '[:lower:]' '[:upper:]')

cd "$(dirname "$0")/.."

if [ ! -d "include/${old}" ]; then
    echo "error: include/${old} not found - has this already been renamed?" >&2
    exit 1
fi

# Contents first, while the paths are still the ones being searched for.
# Build directories are skipped: they hold generated copies that are about to
# be stale anyway.
mapfile -t files < <(
    grep -rl -e "$old" -e "$OLD" . \
        --exclude-dir=.git \
        --exclude-dir=build \
        --exclude-dir=out \
        --binary-files=without-match
)

if [ ${#files[@]} -gt 0 ]; then
    sed -i "s/${OLD}/${NEW}/g; s/${old}/${new}/g" "${files[@]}"
fi

# Then the paths.
mv "include/${old}" "include/${new}"
mv "cmake/${old}-config.cmake.in" "cmake/${new}-config.cmake.in"
mv "cmake/${old}.pc.in" "cmake/${new}.pc.in"

echo "Renamed ${old} -> ${new}."
echo
echo "Next:"
echo "  - rewrite README.md and LICENSE for your project"
echo "  - delete this script"
echo "  - cmake --preset debug && cmake --build --preset debug && ctest --preset debug"
