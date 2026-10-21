#!/bin/sh
# This layer on top of java21-spring-boot must build and pass its tests in a clean directory.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../../scripts/lib/check-common.sh"

credential_grep "$here/skeleton"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -R "$here/../../language/java21-spring-boot/skeleton/." "$work/"
cp -R "$here/skeleton/." "$work/"
gradle_test "$work"
finish
