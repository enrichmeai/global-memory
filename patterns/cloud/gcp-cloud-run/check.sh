#!/bin/sh
# Terraform must be formatted and valid; the image must build, run as non-root on PORT, and answer
# the health probes. Whatever this machine cannot run is SKIP; GM_REQUIRE_ALL=1 (CI) makes a SKIP a failure.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../../scripts/lib/check-common.sh"

tfwork=$(mktemp -d)
work=$(mktemp -d)
container=""
cleanup() {
    [ -n "$container" ] && docker rm -f "$container" >/dev/null 2>&1 || true
    docker rmi global-memory-check:gcp-cloud-run >/dev/null 2>&1 || true
    rm -rf "$tfwork" "$work"
}
trap cleanup EXIT

credential_grep "$here/skeleton"

tf=${TERRAFORM:-terraform}
echo "[terraform fmt]"
if ! command -v "$tf" >/dev/null 2>&1; then
    skip "no terraform on PATH"
elif "$tf" fmt -check -recursive "$here/skeleton/infra"; then
    echo "PASS: terraform fmt"
else
    echo "FAIL: terraform fmt (run terraform fmt -recursive)"; status=1
fi

echo "[terraform validate]"
if [ "${GM_SCHEMA_ONLY:-0}" = "1" ]; then
    echo "SKIP (schema-only run): terraform validate"
elif command -v "$tf" >/dev/null 2>&1; then
    cp -R "$here/skeleton/infra/." "$tfwork/"
    if (cd "$tfwork" && "$tf" init -backend=false -input=false >"$tfwork/init.log" 2>&1); then
        if (cd "$tfwork" && "$tf" validate); then echo "PASS: terraform validate"; else echo "FAIL: terraform validate"; status=1; fi
    elif grep -qiE "registry|dial tcp|could not connect|no such host|timeout|failed to query" "$tfwork/init.log"; then
        tail -5 "$tfwork/init.log"
        skip "terraform init could not reach the provider registry"
    else
        cat "$tfwork/init.log"
        echo "FAIL: terraform init"; status=1
    fi
else
    skip "no terraform on PATH"
fi

echo "[docker build and run]"
if [ "${GM_SCHEMA_ONLY:-0}" = "1" ]; then
    echo "SKIP (schema-only run): docker build and run"
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    cp -R "$here/../../language/java21-spring-boot/skeleton/." "$work/"
    cp "$here/skeleton/Dockerfile" "$here/skeleton/.dockerignore" "$work/"
    if docker build -q -t global-memory-check:gcp-cloud-run "$work" >/dev/null; then
        echo "PASS: docker build"
        container=$(docker run -d -e PORT=8181 -p 127.0.0.1:18181:8181 global-memory-check:gcp-cloud-run)
        uid=$(docker exec "$container" id -u 2>/dev/null || echo "?")
        if [ "$uid" != "0" ] && [ "$uid" != "?" ]; then echo "PASS: runs as uid $uid, not root"; else echo "FAIL: runs as uid $uid"; status=1; fi
        ok=0
        i=0
        while [ $i -lt 60 ]; do
            if curl -fs --max-time 5 http://127.0.0.1:18181/actuator/health/readiness >/dev/null 2>&1; then ok=1; break; fi
            i=$((i + 1)); sleep 2
        done
        if [ $ok -eq 1 ] && curl -fs --max-time 5 http://127.0.0.1:18181/actuator/health/liveness >/dev/null; then
            echo "PASS: listens on PORT=8181 and answers readiness and liveness"
        else
            docker logs "$container" 2>&1 | tail -20
            echo "FAIL: the container did not answer its health probes on PORT"; status=1
        fi
    else
        echo "FAIL: docker build"; status=1
    fi
else
    skip "no docker daemon"
fi
finish
