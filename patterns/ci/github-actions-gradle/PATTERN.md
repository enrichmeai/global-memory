# github-actions-gradle

The CI layer for a Gradle service on GitHub Actions. Every pull request builds and tests the
service, then builds the image and boots it. Every push to `main` does the same, then pushes the
image that passed, tagged `sha-<commit>`. It fits on top of `java21-spring-boot`, and on
`rest-service` and `gcp-cloud-run` when present.

## When it applies
- A Gradle service in a GitHub repository, built on GitHub-hosted runners.

## When it does not
- Maven builds, or GitLab or another CI system: a different layer.
- A library rather than a service: drop the image job and publish the jar instead.

## The decisions and why
- **Two jobs: `build`, then `image`.** The image job waits for the tests. It runs only when the
  repository has a `Dockerfile` (the `gcp-cloud-run` layer's), so this layer also works on its own.
- **The image is booted before anything is pushed.** `.github/scripts/smoke.sh` runs it with
  `PORT=8181` and checks three things: it runs as a non-root user, it listens on `PORT`, and it
  answers `/actuator/health/readiness` and `/liveness`. These are what Cloud Run's probes rely on.
- **Only a push to `main` pushes,** and it pushes the image that passed the smoke test,
  retagged. Nothing is rebuilt between the test and the push.
- **Images are tagged by commit:** `sha-<commit>`, plus a moving `main` tag. Deploy by
  `sha-<commit>`: two runs on `main` can finish out of order and leave `main` on the older commit.
- **Concurrency:** a pull request's runs cancel each other; each push to `main` runs to the end,
  so every merged commit gets its image.
- **Least privilege:** the workflow reads only, and `packages: write` is granted to the image job
  alone. That job's token has write scope on pull request runs too: the main-only guards on the
  login and push steps are what stop a push, and `check.sh` fails if either guard goes missing.
- **Actions are pinned by major version** (`@v4`), as in this repository's own CI. Pin them by
  commit SHA if your policy asks for it.
- **One platform, `linux/amd64`,** which is what Cloud Run runs. Add arm64 only if something runs it.
- **The Gradle version is pinned in the workflow (8.14)** because the language layer has no
  wrapper. With a wrapper, drop `gradle-version` and run `./gradlew`.

## What varies per use
- The branch name, if it is not `main`.
- The registry. The default is GHCR (`ghcr.io/<owner>/<repo>`), using the job's own token, with no
  secret to add. After the first push, check the package's visibility in its settings on GitHub,
  and set it to what your consumers need.
- The Java and Gradle versions, which match the language layer.

## Not included yet
These are added as their own layer once each has really run:
- **Deploying to Cloud Run from CI.** This layer pushes to GHCR, while `gcp-cloud-run` deploys
  from its own Artifact Registry repository. So with that layer, the deploy is still its step 2
  (push to Artifact Registry) and step 3 (`terraform apply`). Doing it from CI needs Workload
  Identity Federation, and that has not yet run here.
- **Signed build provenance and an SBOM.**

## Check
`check.sh` does the following:
1. Lints the workflow with `actionlint`.
2. Checks that the GHCR login and the push run only on a push to `main`, and that nothing pushes
   from the build step.
3. Composes this layer with `java21-spring-boot`, `rest-service` and `gcp-cloud-run`'s
   Dockerfile in a clean directory.
4. Runs the **same Gradle command, read from the workflow**.
5. Builds the image and runs the **same `smoke.sh`** the workflow runs.

So the commands in the workflow are the ones proven, not a copy of them. Whatever this machine
can't run is reported as SKIP. `GM_REQUIRE_ALL=1` (set in CI) turns a SKIP into a failure.
