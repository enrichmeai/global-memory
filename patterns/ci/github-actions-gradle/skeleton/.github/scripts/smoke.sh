#!/bin/sh
# Boot the image exactly as built and prove what Cloud Run's probes rely on: it runs as a
# non-root user, listens on PORT, and answers readiness and liveness. The CI workflow runs this
# before any push, so a broken image never reaches the registry.
# Usage: smoke.sh IMAGE [HOST_PORT]
set -eu
image=$1
host_port=${2:-18181}
name="smoke-$$"
cleanup() { docker rm -f "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "$name" -e PORT=8181 -p "127.0.0.1:$host_port:8181" "$image" >/dev/null

uid=$(docker exec "$name" id -u 2>/dev/null || echo "?")
if [ "$uid" = "?" ]; then
    docker logs "$name" 2>&1 | tail -25
    echo "FAIL: the container is not running (it exited at startup)"
    exit 1
fi
if [ "$uid" = "0" ]; then
    echo "FAIL: the container runs as uid 0; it must not be root"
    exit 1
fi
echo "PASS: runs as uid $uid"

# A JVM can take tens of seconds on a small runner: allow 2 minutes.
i=0
until curl -fs --max-time 5 "http://127.0.0.1:$host_port/actuator/health/readiness" >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)" != "true" ]; then
        docker logs "$name" 2>&1 | tail -25
        echo "FAIL: the container exited before it was ready"
        exit 1
    fi
    if [ "$i" -ge 60 ]; then
        docker logs "$name" 2>&1 | tail -25
        echo "FAIL: no readiness answer on PORT=8181 within 2 minutes"
        exit 1
    fi
    sleep 2
done
if ! curl -fs --max-time 5 "http://127.0.0.1:$host_port/actuator/health/liveness" >/dev/null; then
    docker logs "$name" 2>&1 | tail -25
    echo "FAIL: ready, but no liveness answer"
    exit 1
fi
echo "PASS: listens on PORT=8181 and answers readiness and liveness"
