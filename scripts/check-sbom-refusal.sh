#!/usr/bin/env bash
#
# The application templates install no SBOM, and each one quotes the message
# install(SBOM) refuses it with and the CMake version that answered. This adds
# install(SBOM) to a copy of the template and requires CMake to answer with
# that sentence, having checked that it is that version.
#
#   ./scripts/check-sbom-refusal.sh templates/cli templates/daemon
#
# Run it with the pinned CMake, and run the qt template where Qt is. This is a
# monorepo check: a published template has no sibling to read the experimental
# gate from.

set -euo pipefail

[ $# -ge 1 ] || { echo "usage: $0 <template-directory>..." >&2; exit 1; }

readonly marker="the rules this check adds were reached"

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

cmake_version=$(cmake --version | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' || true)
[ -n "$cmake_version" ] || { echo "error: cmake --version names no version" >&2; exit 1; }

# CMake wraps what it prints, and the comments quote its target names without
# the quotes it puts around them.
normalise() { tr -s '[:space:]' ' ' | tr -d '"'; }

check() {
    local template=${1%/}
    local lists="${template}/CMakeLists.txt"
    [ -f "$lists" ] || { echo "error: no ${lists}" >&2; return 1; }

    # The gate is read from the library template rather than copied, so the two
    # move together.
    local gate_source gate
    gate_source="$(dirname "$template")/lib/CMakeLists.txt"
    gate=$(grep -oP 'set\(CMAKE_EXPERIMENTAL_GENERATE_SBOM "\K[^"]+' "$gate_source" 2> /dev/null | head -1 || true)
    [ -n "$gate" ] \
        || { echo "error: ${gate_source} sets no CMAKE_EXPERIMENTAL_GENERATE_SBOM to gate install(SBOM) with" >&2; return 1; }

    local measured
    measured=$(grep -oiP 'measured with cmake \K[0-9]+\.[0-9]+\.[0-9]+' "$lists" | head -1 || true)
    [ -n "$measured" ] || { echo "error: ${lists} names no CMake version it was measured with" >&2; return 1; }

    if [ "$measured" != "$cmake_version" ]; then
        echo "error: ${lists} quotes CMake ${measured}, and this is ${cmake_version}" >&2
        echo "Run it with the pinned CMake, or measure it again and write down what it answers." >&2
        return 1
    fi

    local -a quotes
    mapfile -t quotes < <(sed -n 's/^#[[:space:]]\?//p' "$lists" | tr '\n' ' ' \
        | grep -oP '"[^"]*covered by any SBOM[^"]*"' || true)
    if [ ${#quotes[@]} -ne 1 ]; then
        echo "error: ${lists} has ${#quotes[@]} comment quotes of a refusal; this check reads one" >&2
        return 1
    fi
    local quote=${quotes[0]//\"/}

    local target testing installing
    target=$(grep -oP '^install\(TARGETS \K[A-Za-z0-9_]+' "$lists" | head -1 || true)
    [ -n "$target" ] || { echo "error: ${lists} installs no target to ask for an SBOM of" >&2; return 1; }
    testing=$(grep -oP '^option\(\K[A-Z0-9_]+_BUILD_TESTING' "$lists" | head -1 || true)
    [ -n "$testing" ] || { echo "error: ${lists} declares no *_BUILD_TESTING option" >&2; return 1; }
    installing=$(grep -oP '^option\(\K[A-Z0-9_]+_INSTALL' "$lists" | head -1 || true)
    [ -n "$installing" ] || { echo "error: ${lists} declares no *_INSTALL option" >&2; return 1; }

    local work="${root}/${template##*/}"
    mkdir -p "$work/src"

    # Tracked files only, like this repository's other checks, and with the
    # symlinked cmake/modules resolved. The copy is read as root in the pinned
    # image, where the checkout belongs to somebody else.
    if ! git -c safe.directory='*' -C "$template" ls-files -z \
        | tar -C "$template" -ch --null -T - -f - \
        | tar -C "$work/src" -xf -; then
        echo "error: could not copy ${template}" >&2
        return 1
    fi

    cat >> "$work/src/CMakeLists.txt" << RULES

message(STATUS "${marker}")
set(CMAKE_EXPERIMENTAL_GENERATE_SBOM "${gate}")
install(TARGETS ${target} EXPORT ${target}-targets RUNTIME DESTINATION bin)
install(SBOM ${target} EXPORTS ${target}-targets LICENSE "0BSD")
RULES

    local log="$work/configure.log" configured=0
    cmake -S "$work/src" -B "$work/build" -G Ninja \
        "-D${testing}=OFF" "-D${installing}=ON" \
        "-DFETCHCONTENT_BASE_DIR=${root}/fetched" > "$log" 2>&1 && configured=1

    # The template returns early when it installs nothing, which would skip the
    # rules above and read as CMake accepting them.
    if ! grep -qF -- "$marker" "$log"; then
        echo "error: the install(SBOM) added to ${template} was never reached" >&2
        tail -20 "$log" >&2
        return 1
    fi

    if [ "$configured" -eq 1 ]; then
        echo "error: ${template} configures with install(SBOM) added; CMake accepts what the comment says it refuses" >&2
        echo "Measure it again and rewrite the comment in ${lists}." >&2
        return 1
    fi

    if ! normalise < "$log" | grep -qF -- "$(printf '%s' "$quote" | normalise)"; then
        echo "error: ${template} refuses install(SBOM) in words ${lists} does not quote" >&2
        echo "--- quoted there ---" >&2
        printf '%s\n' "$quote" >&2
        echo "--- what CMake said ---" >&2
        grep -B2 -A8 'CMake Error' "$log" >&2 || cat "$log" >&2
        return 1
    fi

    printf '%s: install(SBOM) refuses %s in the words its comment quotes, measured with CMake %s.\n' \
        "$template" "$target" "$cmake_version"
}

# Every template is looked at, so that one of them does not hide the next.
status=0
for template in "$@"; do
    check "$template" || status=1
done
exit "$status"
