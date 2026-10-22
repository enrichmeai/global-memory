# Adding a layer

1. Pick the category folder (`patterns/language/`, `architecture/`, `cloud/` or `ci/`) and an id
   (`[a-z0-9-]`) that is unique across all categories. Name it for what it is, most specific last:
   `java21-spring-boot`, `gcp-cloud-run`, `github-actions-gradle`. A new category needs an issue first.
2. Write `PATTERN.md`: when it applies, when it does not, each decision with its reason, and what varies.
3. Put the files in `skeleton/` with working defaults. A layer that sits on another (`rest-service` on
   `java21-spring-boot`) must work when both are copied into one directory, so no two layers that
   combine may ship the same file.
4. Write `check.sh` using `scripts/lib/check-common.sh`. It must fail on a broken skeleton:
   show that once (break a test, see FAIL) before opening the PR.
5. Fill in `manifest.yaml`, with `verified-against` naming the versions you proved it with.
   List in `sources.yaml` the official docs and release pages the decisions rest on, each with a
   `url` (https) and `what` it backs. It is a file of its own because memory format v1's manifest
   takes no extra keys. `scripts/check-sources.sh` checks the shape (blocking on every PR) and that
   every url resolves (the weekly `sources` job, and on demand: Actions → check → Run workflow).
   A host that answers every path (a single-page docs site) only proves the host is up, so check
   the page yourself when you add it.
6. Open a PR with the `check.sh` output pasted in. CI must be green.

Only build a layer from something that has really run. A pattern is a record of what worked, not a guess.
