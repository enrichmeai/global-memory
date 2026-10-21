#!/bin/sh
# The workflow must lint clean and keep its one rule (nothing is pushed except from main), and the
# commands it runs must really pass on the composed layers: the same Gradle command, read from the
# workflow, then the image built with the cloud layer's Dockerfile and booted by the same smoke.sh.
# Whatever this machine cannot run is SKIP; GM_REQUIRE_ALL=1 (CI) makes a SKIP a failure.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../../scripts/lib/check-common.sh"
wf="$here/skeleton/.github/workflows/ci.yml"

work=$(mktemp -d)
cleanup() {
    docker rmi global-memory-check:ci >/dev/null 2>&1 || true
    rm -rf "$work"
}
trap cleanup EXIT

credential_grep "$here/skeleton"

echo "[actionlint]"
al=${ACTIONLINT:-actionlint}
if [ "${GM_SCHEMA_ONLY:-0}" = "1" ]; then
    echo "SKIP (schema-only run): actionlint"
elif ! command -v "$al" >/dev/null 2>&1; then
    skip "no actionlint on PATH"
elif "$al" "$wf"; then
    echo "PASS: actionlint"
else
    echo "FAIL: actionlint"; status=1
fi

echo "[only main pushes]"
main_guard="if: github.event_name == 'push' && github.ref == 'refs/heads/main'"
shape_ok=1
for step in "Log in to GHCR" "Push sha-<commit> and main"; do
    if ! grep -qF -- "- name: $step" "$wf"; then
        echo "FAIL: no step named '$step' (rename it here too)"; shape_ok=0
    elif ! grep -A1 -F -- "- name: $step" "$wf" | grep -qF -- "$main_guard"; then
        echo "FAIL: step '$step' must have '$main_guard' on the line after its name"; shape_ok=0
    fi
done
# Anything but the guarded docker push that could publish: build-push-action's push input (any
# value; indented as a step input, unlike the on: push trigger), a registry exporter, or
# buildx --push. Comments are ignored.
if grep -v '^[[:space:]]*#' "$wf" | grep -qE '^[[:space:]]{6,}push:|type=registry|buildx[^#]*--push'; then
    echo "FAIL: something pushes outside the guarded step; push only the smoke-tested image, from main"; shape_ok=0
fi
if [ "$(grep -v '^[[:space:]]*#' "$wf" | grep -c 'docker push')" -ne 2 ]; then
    echo "FAIL: expected exactly the two docker push lines inside the guarded step"; shape_ok=0
fi
if [ $shape_ok -eq 1 ]; then echo "PASS: login and push run only on a push to main"; else status=1; fi

# The layers this one sits on, composed as a user would.
cp -R "$here/../../language/java21-spring-boot/skeleton/." "$work/"
cp -R "$here/../../architecture/rest-service/skeleton/." "$work/"
cp "$here/../../cloud/gcp-cloud-run/skeleton/Dockerfile" "$here/../../cloud/gcp-cloud-run/skeleton/.dockerignore" "$work/"
cp -R "$here/skeleton/." "$work/"

echo "[the workflow's build command]"
build_cmd=$(sed -n 's/^[[:space:]]*run: \(gradle .*\)$/\1/p' "$wf")
if [ -z "$build_cmd" ]; then
    echo "FAIL: no 'run: gradle ...' step in the workflow"; status=1
elif [ "${GM_SCHEMA_ONLY:-0}" = "1" ]; then
    echo "SKIP (schema-only run): $build_cmd"
elif ! command -v gradle >/dev/null 2>&1; then
    skip "no gradle on PATH"
else
    offline=""
    [ "${GM_GRADLE_OFFLINE:-0}" = "1" ] && offline="--offline"
    if (cd "$work" && $build_cmd -q $offline); then
        echo "PASS: $build_cmd"
    else
        echo "FAIL: $build_cmd"; status=1
    fi
fi

echo "[image build and smoke.sh]"
if [ "${GM_SCHEMA_ONLY:-0}" = "1" ]; then
    echo "SKIP (schema-only run): image build and smoke.sh"
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    if docker build -q -t global-memory-check:ci "$work" >/dev/null; then
        echo "PASS: docker build"
        if (cd "$work" && sh .github/scripts/smoke.sh global-memory-check:ci 18182); then
            echo "PASS: smoke.sh"
        else
            echo "FAIL: smoke.sh"; status=1
        fi
    else
        echo "FAIL: docker build"; status=1
    fi
else
    skip "no docker daemon"
fi
finish
