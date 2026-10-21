#!/bin/sh
# Terraform must be formatted and valid, and the Dockerfile must build the language layer into an image.
# Whatever this machine cannot run is SKIP; GM_REQUIRE_ALL=1 (CI) makes a SKIP a failure.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../scripts/lib/check-common.sh"

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
if command -v "$tf" >/dev/null 2>&1; then
    tfwork=$(mktemp -d)
    cp -R "$here/skeleton/infra/." "$tfwork/"
    if (cd "$tfwork" && "$tf" init -backend=false -input=false >/dev/null 2>&1); then
        if (cd "$tfwork" && "$tf" validate); then echo "PASS: terraform validate"; else echo "FAIL: terraform validate"; status=1; fi
    else
        skip "terraform init could not reach the provider registry"
    fi
    rm -rf "$tfwork"
else
    skip "no terraform on PATH"
fi

echo "[docker build]"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    work=$(mktemp -d)
    cp -R "$here/../java21-spring-boot/skeleton/." "$work/"
    cp "$here/skeleton/Dockerfile" "$here/skeleton/.dockerignore" "$work/"
    if docker build -q -t global-memory-check:gcp-cloud-run "$work" >/dev/null; then
        echo "PASS: docker build"
        docker rmi global-memory-check:gcp-cloud-run >/dev/null 2>&1 || true
    else
        echo "FAIL: docker build"; status=1
    fi
    rm -rf "$work"
else
    skip "no docker daemon"
fi
finish
