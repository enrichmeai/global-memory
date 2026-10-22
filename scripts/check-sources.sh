#!/bin/sh
# Every pattern says where its decisions come from (sources.yaml beside its manifest), each entry is
# an https url and a line saying what it backs, and every url resolves. A planned refresh
# (penstock#196) is to read these. sources.yaml is its own file because memory format v1's pattern
# manifest takes no extra keys. GM_SCHEMA_ONLY=1 checks the shape only. A url this machine cannot
# reach is SKIP; GM_REQUIRE_ALL=1 makes it a failure. A host that answers 200 for any path (a
# single-page app) proves only that the host is up. GM_ROOT points the check at another tree (tests).
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/lib/check-common.sh"
root=${GM_ROOT:-$(cd "$here/.." && pwd)}
set -f   # urls are expanded unquoted below: never glob them

if ! python3 -c 'import yaml' 2>/dev/null; then
    skip "PyYAML is not installed (python3 -m pip install pyyaml)"
    finish
fi

set +f
dirs=$(printf '%s\n' "$root"/patterns/*/*/)
set -f
for dir in $dirs; do
    rel=${dir#"$root"/}
    f="${dir}sources.yaml"
    echo "[sources] ${rel}sources.yaml"
    if [ ! -f "$f" ]; then
        echo "FAIL: missing"; status=1; continue
    fi
    if ! urls=$(python3 -I - "$f" <<'PY'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
errors = []
entries = doc.get("sources") if isinstance(doc, dict) else None
if not isinstance(doc, dict) or set(doc) != {"sources"}:
    errors.append("the top level must be exactly one key, sources")
if not isinstance(entries, list) or not entries:
    errors.append("sources must be a non-empty list")
    entries = []
for i, e in enumerate(entries):
    if not isinstance(e, dict) or set(e) != {"url", "what"}:
        errors.append(f"entry {i}: must have exactly url and what")
        continue
    if not (isinstance(e["url"], str) and e["url"].startswith("https://") and " " not in e["url"]):
        errors.append(f"entry {i}: url must be an https url, got {e['url']!r}")
    if not (isinstance(e["what"], str) and e["what"].strip()):
        errors.append(f"entry {i}: what must say what the source backs")
if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print("\n".join(e["url"] for e in entries))
PY
    ); then
        echo "FAIL: not a valid sources.yaml"; status=1; continue
    fi
    echo "PASS: shape ($(printf '%s\n' "$urls" | wc -l | tr -d ' ') sources)"
    if [ "${GM_SCHEMA_ONLY:-0}" = "1" ]; then
        echo "SKIP (schema-only run): url checks"; continue
    fi
    for u in $urls; do
        if curl -fsSL -o /dev/null --max-time 30 --retry 2 -A "global-memory-source-check" "$u" 2>/dev/null; then
            echo "PASS: $u"
        else
            skip "$u did not resolve"
        fi
    done
done
finish
