#!/bin/sh
# The skeleton must build and its test must pass, in a clean directory. A step this machine
# cannot run is reported as SKIP (not run), never as a pass.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../../scripts/lib/check-common.sh"

credential_grep "$here/skeleton"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -R "$here/skeleton/." "$work/"
gradle_test "$work"
finish
