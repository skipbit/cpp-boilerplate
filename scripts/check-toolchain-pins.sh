#!/usr/bin/env bash
#
# Every .devcontainer/Dockerfile in this repository has to pin the same
# toolchain, and to carry the same archive signing keys beside it. Every comment
# that names the CMake version something was measured with names the pinned one.
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
readonly shared_dir="${shared%/*}"
[ -f "$shared" ] || { echo "error: no $shared" >&2; exit 1; }

pins() { grep -E '^ARG [A-Z_]+=' "$1" | sort; }

# The names are whatever sits beside the shared Dockerfile. Adding a key means
# naming it in each COPY as well; this says only that the copies agree.
keys=()
while IFS= read -r path; do
    keys+=("${path##*/}")
done < <(git ls-files -- "${shared_dir}/*-keyring.asc" | sort)

copies=()
while IFS= read -r path; do
    [ "$path" = "$shared" ] || copies+=("$path")
done < <(git ls-files -- '*.devcontainer/Dockerfile' | sort)

# Matching nothing is a failure, not a pass. Either list coming back empty
# leaves a check that reports success by having had nothing to compare.
if [ ${#keys[@]} -eq 0 ]; then
    echo "error: no ${shared_dir}/*-keyring.asc; this would have passed by finding no keys" >&2
    exit 1
fi
if [ ${#copies[@]} -eq 0 ]; then
    echo "error: ${shared} is the only .devcontainer/Dockerfile; this would have passed by finding no copies" >&2
    echo "If no template ships its own image any more, there is nothing to compare and this script should go." >&2
    exit 1
fi

# The names come out of the index and the comparison below reads the working
# tree. A shared key staged for removal would otherwise make every copy of it
# look like the wrong one.
for key in "${keys[@]}"; do
    [ -f "${shared_dir}/${key}" ] \
        || { echo "error: ${shared_dir}/${key} is in the index and not on disk" >&2; exit 1; }
done

expected=$(pins "$shared")
differing=()

for file in "${copies[@]}"; do
    dir="${file%/*}"

    if [ "$(pins "$file")" != "$expected" ]; then
        differing+=("$file")
        echo "--- ${file} against ${shared} ---" >&2
        diff <(echo "$expected") <(pins "$file") >&2 || true
    fi

    for key in "${keys[@]}"; do
        if [ ! -f "${dir}/${key}" ]; then
            differing+=("${dir}/${key}")
            echo "--- ${dir}/${key} is missing, and ${shared_dir}/${key} is there ---" >&2
        elif ! cmp -s "${shared_dir}/${key}" "${dir}/${key}"; then
            differing+=("${dir}/${key}")
            echo "--- ${dir}/${key} is not a copy of ${shared_dir}/${key} ---" >&2
        fi
    done

    # And the other direction, which the loop above cannot see: a key here that
    # the shared directory has no name for sits in a build context, in the
    # published template, and in nobody's COPY.
    while IFS= read -r path; do
        case " ${keys[*]} " in
            *" ${path##*/} "*) ;;
            *)
                differing+=("$path")
                echo "--- ${path} has no counterpart in ${shared_dir} ---" >&2
                ;;
        esac
    done < <(git ls-files -- "${dir}/*-keyring.asc" | sort)
done

pinned_cmake=$(grep -oP '^ARG CMAKE_VERSION=\K[0-9]+\.[0-9]+\.[0-9]+' "$shared" | head -1)
[ -n "$pinned_cmake" ] \
    || { echo "error: ${shared} pins no ARG CMAKE_VERSION with a version in it" >&2; exit 1; }

measured=()
while IFS= read -r line; do
    measured+=("$line")
done < <(git grep -niE 'measured with cmake [0-9]+\.[0-9]+\.[0-9]+' -- . || true)

# Matching nothing is a failure, not a pass.
if [ ${#measured[@]} -eq 0 ]; then
    echo "error: nothing names a CMake version it was measured with; this would have passed by finding nothing to read" >&2
    exit 1
fi

stale=()
for line in "${measured[@]}"; do
    where=$(printf '%s' "$line" | cut -d: -f1,2)
    while IFS= read -r version; do
        [ "$version" = "$pinned_cmake" ] || stale+=("${where} names CMake ${version}")
    done < <(printf '%s' "$line" | grep -oiP 'measured with cmake \K[0-9]+\.[0-9]+\.[0-9]+')
done

failed=0

if [ ${#differing[@]} -gt 0 ]; then
    echo >&2
    echo "error: these disagree with what ${shared} pins and verifies:" >&2
    printf '  %s\n' "${differing[@]}" >&2
    echo >&2
    echo "Bump or copy them together, or say in ${shared} why one of them is" >&2
    echo "deliberately behind. A copy nobody compares is a copy that stops being" >&2
    echo "one." >&2
    failed=1
fi

if [ ${#stale[@]} -gt 0 ]; then
    echo >&2
    echo "error: these name a CMake version ${shared} no longer pins (${pinned_cmake}):" >&2
    printf '  %s\n' "${stale[@]}" >&2
    echo >&2
    echo "Measure them again with the pinned version; scripts/check-sbom-refusal.sh" >&2
    echo "is what re-measures the install(SBOM) refusals." >&2
    failed=1
fi

[ "$failed" -eq 0 ] || exit 1

echo "These agree with ${shared} and the ${#keys[@]} keys beside it:"
printf '  %s\n' "${copies[@]}"
echo "These were measured with the pinned CMake ${pinned_cmake}:"
printf '%s\n' "${measured[@]%%:*}" | sort -u | sed 's/^/  /'
