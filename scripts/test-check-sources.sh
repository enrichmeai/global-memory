#!/bin/sh
# Fixtures for check-sources.sh's shape rules: each broken tree must FAIL, the good one must PASS.
# Shape only (GM_SCHEMA_ONLY=1), so it needs no network.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

tree() {  # tree NAME CONTENT: a one-pattern tree whose sources.yaml is CONTENT ("-" for none)
    mkdir -p "$tmp/$1/patterns/cat/p"
    [ "$2" = "-" ] || printf '%s\n' "$2" > "$tmp/$1/patterns/cat/p/sources.yaml"
}
expect() {  # expect NAME pass|fail
    if GM_ROOT="$tmp/$1" GM_SCHEMA_ONLY=1 sh "$here/check-sources.sh" >"$tmp/$1.out" 2>&1; then got=pass; else got=fail; fi
    if [ "$got" = "$2" ]; then echo "ok: $1 ($2)"; else echo "WRONG: $1 expected $2, got $got"; cat "$tmp/$1.out"; fails=1; fi
}

tree good 'sources:
  - url: https://example.com/doc
    what: a doc'
tree missing -
tree http 'sources:
  - url: http://example.com/doc
    what: a doc'
tree no-what 'sources:
  - url: https://example.com/doc'
tree empty-what 'sources:
  - url: https://example.com/doc
    what: ""'
tree empty-list 'sources: []'
tree extra-key 'sources:
  - url: https://example.com/doc
    what: a doc
    note: x'
tree extra-top 'sources:
  - url: https://example.com/doc
    what: a doc
other: 1'

expect good pass
for t in missing http no-what empty-what empty-list extra-key extra-top; do expect "$t" fail; done
[ $fails -eq 0 ] && echo "RESULT: PASS" || { echo "RESULT: FAIL"; exit 1; }
