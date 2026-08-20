#!/usr/bin/env bash
#
# Renames the library. Run once, when this becomes your project:
#
#   ./scripts/rename.sh yourlib
#   ./scripts/rename.sh yourlib https://github.com/you/yourlib
#
# Covers the namespace, the target, the installed package, the generated
# headers and the include directory. The uppercase form (export macros, CMake
# options) follows automatically.
#
# Not .clang-tidy: its naming rules are about case, not about this project, so
# there is nothing in it to rename.
#
# The homepage in project() is covered too, and it is not decoration: CMake
# writes PROJECT_HOMEPAGE_URL into the installed SBOM, so a copy that keeps the
# original URL hands every consumer a supply-chain document pointing at the
# template instead of at this library. Given no URL, the origin remote is used;
# with no usable origin either the line is deleted, because a missing homepage
# is honest and a wrong one is not.

set -euo pipefail

readonly old="mylib"
readonly OLD="MYLIB"

usage() {
    echo "usage: $0 <new-name> [homepage-url]" >&2
    echo "  new-name:     lowercase, starting with a letter, e.g. audiokit" >&2
    echo "  homepage-url: an http(s) URL; taken from the origin remote if omitted" >&2
    exit 2
}

# Turns a git remote of any of the usual shapes into a browsable https URL.
# Fails, printing nothing, when it is not one of them.
homepage_from_remote() {
    local url=${1%.git}
    case "$url" in
        ssh://*)   url=${url#ssh://} ;;
        https://*) url=${url#https://} ;;
        http://*)  url=${url#http://} ;;
        git://*)   url=${url#git://} ;;
        *@*:*)     url=${url#*@}; url=${url/:/\/} ;;
        *)         return 1 ;;
    esac
    url=${url#*@}  # any user info that survived the scheme
    case "$url" in
        */*/*) printf 'https://%s\n' "$url" ;;
        *)     return 1 ;;
    esac
}

[ $# -ge 1 ] && [ $# -le 2 ] || usage
new="$1"
homepage="${2:-}"

if ! [[ "$new" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "error: '$new' must be lowercase and start with a letter" >&2
    usage
fi

if [ "$new" = "$old" ]; then
    echo "error: that is already the name" >&2
    exit 1
fi

if [ -n "$homepage" ] && ! [[ "$homepage" =~ ^https?://[^[:space:]]+$ ]]; then
    echo "error: '$homepage' is not an http(s) URL" >&2
    usage
fi

NEW=$(printf '%s' "$new" | tr '[:lower:]' '[:upper:]')

cd "$(dirname "$0")/.."

if [ ! -d "include/${old}" ]; then
    echo "error: include/${old} not found - has this already been renamed?" >&2
    exit 1
fi

if [ -z "$homepage" ]; then
    origin=$(git config --get remote.origin.url 2>/dev/null || true)
    if [ -n "$origin" ]; then
        homepage=$(homepage_from_remote "$origin" || true)
    fi
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

# The homepage carries no occurrence of the old name, so it survives the
# substitution above and has to be handled on its own.
if [ -n "$homepage" ]; then
    sed -i "s|^\([[:space:]]*HOMEPAGE_URL[[:space:]]\).*|\1\"${homepage}\"|" CMakeLists.txt
else
    sed -i '/^[[:space:]]*HOMEPAGE_URL[[:space:]]/d' CMakeLists.txt
fi

# Then the paths.
mv "include/${old}" "include/${new}"
mv "cmake/${old}-config.cmake.in" "cmake/${new}-config.cmake.in"
mv "cmake/${old}.pc.in" "cmake/${new}.pc.in"

echo "Renamed ${old} -> ${new}."
if [ -n "$homepage" ]; then
    echo "Homepage: ${homepage}"
else
    echo "Homepage: removed - no URL given, and origin has none this script could read."
fi
echo
echo "Next:"
echo "  - rewrite README.md and LICENSE for your project"
if [ -z "$homepage" ]; then
    echo "  - put HOMEPAGE_URL back in project() once this has a home to point at"
fi
echo "  - delete this script"
echo "  - cmake --preset debug && cmake --build --preset debug && ctest --preset debug"
