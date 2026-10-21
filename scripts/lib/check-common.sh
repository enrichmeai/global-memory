# Shared by every pattern's check.sh. GM_SCHEMA_ONLY=1 skips the slow steps (build, run, validate)
# for a job that only validates cards; such a run proves nothing about the skeletons. POSIX sh. Each check prints PASS, FAIL or SKIP (not run);
# finish exits non-zero on any FAIL. A SKIP is never counted as a pass in a summary.
status=0

credential_grep() {
    echo "[credential-grep] $1"
    if [ ! -d "$1" ]; then
        echo "FAIL: no such directory"; status=1; return 0
    fi
    # Known key prefixes anywhere, or a quoted literal of real length assigned to a password, token or secret.
    if grep -rEn '(sk-[A-Za-z0-9]{10,}|ghp_[A-Za-z0-9]{10,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{10,}|AIza[0-9A-Za-z_-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(password|token|secret)[[:space:]]*[:=][[:space:]]*"[^"<$[:space:]]{8,}")' "$1" 2>/dev/null; then
        echo "FAIL: a credential-shaped value"
        status=1
    else
        echo "PASS: no credential-shaped value"
    fi
}

gradle_test() {
    echo "[gradle test] $1"
    if [ "${GM_SCHEMA_ONLY:-0}" = "1" ]; then
        echo "SKIP (schema-only run): gradle test"
        return 0
    fi
    if ! command -v gradle >/dev/null 2>&1; then
        skip "no gradle on PATH"
        return 0
    fi
    offline=""
    [ "${GM_GRADLE_OFFLINE:-0}" = "1" ] && offline="--offline"
    if (cd "$1" && gradle --no-daemon -q $offline test); then
        echo "PASS: gradle test"
    else
        echo "FAIL: gradle test"
        status=1
    fi
}

# A check this machine cannot run. GM_REQUIRE_ALL=1 (CI) makes that a failure, not a pass.
skip() {
    if [ "${GM_REQUIRE_ALL:-0}" = "1" ]; then
        echo "FAIL (required): $1"
        status=1
    else
        echo "SKIP (not run): $1"
    fi
}

finish() {
    if [ "$status" -ne 0 ]; then
        echo "RESULT: FAIL"
        exit 1
    fi
    echo "RESULT: PASS (any SKIP above was not run)"
}
