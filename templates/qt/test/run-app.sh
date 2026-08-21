#!/usr/bin/env bash
#
# Starts the built program the way somebody at a desktop would, without the
# desktop. QT_QPA_PLATFORM=offscreen is what makes that possible, and it is why
# a GUI application can be checked by the same CI as everything else here.

set -euo pipefail

program=${1:?usage: run-app.sh <program> <work-dir>}
work=${2:?usage: run-app.sh <program> <work-dir>}

rm -rf "$work"
mkdir -p "$work"

export QT_QPA_PLATFORM=offscreen

fail() {
    echo "$*" >&2
    for log in "$work"/*.log; do
        [ -f "$log" ] || continue
        echo "--- ${log} ---" >&2
        sed 's/^/  /' "$log" >&2
    done
    exit 1
}

run() {
    local name=$1
    shift
    local status=0
    "$program" "$@" > "$work/${name}.log" 2>&1 || status=$?
    echo "$status"
}

# --self-check builds the window, draws it once and quits. That covers main(),
# startup, the window and every layer under it, in the order a user would.
[ "$(run self-check --self-check)" = "0" ] || fail "--self-check did not exit 0"

# The version comes from project(VERSION) through the generated header, so this
# also says the two have not drifted apart.
[ "$(run version --version)" = "0" ] || fail "--version did not exit 0"
grep -qE '^myapp [0-9]+\.[0-9]+\.[0-9]+$' "$work/version.log" \
    || fail "--version printed '$(cat "$work/version.log")'"

# An option nobody added is the ordinary way to get this wrong, so it is the one
# worth pinning down: it has to fail rather than start.
[ "$(run nonsense --nonsense)" != "0" ] || fail "an unknown option was accepted"

echo "starts headless, answers --version, refuses an unknown option."
