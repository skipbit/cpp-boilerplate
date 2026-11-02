#!/usr/bin/env bash
#
# The application templates install no SBOM, and each quotes the message
# install(SBOM) refuses it with. This adds install(SBOM) to a copy of the
# template and requires CMake to answer with the sentence quoted there.
#
#   ./scripts/check-sbom-refusal.sh templates/cli
#
# Run it with the pinned CMake, the version those comments name, and run the qt
# template where Qt is. This is a monorepo check: a published template has no
# sibling to read the experimental gate from.

set -euo pipefail

[ $# -eq 1 ] || { echo "usage: $0 <template-directory>" >&2; exit 1; }

template=${1%/}
lists="${template}/CMakeLists.txt"
[ -f "$lists" ] || { echo "error: no ${lists}" >&2; exit 1; }

# The gate is read from the library template rather than copied, so the two
# move together.
gate_source="$(dirname "$template")/lib/CMakeLists.txt"
[ -f "$gate_source" ] || { echo "error: no ${gate_source} to read the experimental gate from" >&2; exit 1; }

gate=$(grep -oP 'set\(CMAKE_EXPERIMENTAL_GENERATE_SBOM "\K[^"]+' "$gate_source" | head -1)
[ -n "$gate" ] \
    || { echo "error: ${gate_source} sets no CMAKE_EXPERIMENTAL_GENERATE_SBOM to gate install(SBOM) with" >&2; exit 1; }

mapfile -t quotes < <(sed -n 's/^#[[:space:]]\?//p' "$lists" \
    | tr '\n' ' ' \
    | grep -oP '"[^"]*covered by any SBOM[^"]*"')

if [ ${#quotes[@]} -ne 1 ]; then
    echo "error: ${lists} has ${#quotes[@]} comment quotes of a refusal; this check reads one" >&2
    exit 1
fi

quote=${quotes[0]//\"/}

target=$(grep -oP '^install\(TARGETS \K[A-Za-z0-9_]+' "$lists" | head -1)
[ -n "$target" ] || { echo "error: ${lists} installs no target to ask for an SBOM of" >&2; exit 1; }

testing=$(grep -oP '^option\(\K[A-Z0-9_]+_BUILD_TESTING' "$lists" | head -1)
[ -n "$testing" ] || { echo "error: ${lists} declares no *_BUILD_TESTING option" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# -L resolves cmake/modules, a symlink in this tree.
cp -rL "$template/." "$work/"

cat >> "$work/CMakeLists.txt" << RULES

set(CMAKE_EXPERIMENTAL_GENERATE_SBOM "${gate}")
install(TARGETS ${target} EXPORT ${target}-targets RUNTIME DESTINATION bin)
install(SBOM ${target} EXPORTS ${target}-targets LICENSE "0BSD")
RULES

log="$work/configure.log"

if cmake -S "$work" -B "$work/build" -G Ninja "-D${testing}=OFF" > "$log" 2>&1; then
    echo "error: ${template} configures with install(SBOM) added; CMake accepts what the comment says it refuses" >&2
    echo "Measure it again and rewrite the comment in ${lists}." >&2
    exit 1
fi

# CMake wraps what it prints, and the comments quote its target names without
# the quotes it puts around them.
normalise() { tr -s '[:space:]' ' ' | tr -d '"'; }

if ! normalise < "$log" | grep -qF "$(printf '%s' "$quote" | normalise)"; then
    echo "error: ${template} refuses install(SBOM) in words ${lists} does not quote" >&2
    echo "--- quoted there ---" >&2
    echo "$quote" >&2
    echo "--- what CMake said ---" >&2
    grep -B2 -A8 'CMake Error' "$log" >&2 || cat "$log" >&2
    exit 1
fi

echo "${template}: install(SBOM) refuses ${target} in the words its comment quotes ($(cmake --version | head -1))."
