# Adding a layer

1. Pick the row (language, architecture, cloud or CI) and a short id (`[a-z0-9-]`).
2. Write `PATTERN.md`: when it applies, when it does not, each decision with its reason, and what varies.
3. Put the files in `skeleton/` with working defaults. A layer that sits on another (`rest-service` on
   `java21-spring-boot`) must work when both are copied into one directory.
4. Write `check.sh` using `scripts/lib/check-common.sh`. It must fail on a broken skeleton:
   show that once (break a test, see FAIL) before opening the PR.
5. Fill in `manifest.yaml`, with `verified-against` naming the versions you proved it with.
6. Open a PR with the `check.sh` output pasted in. CI must be green.

Only build a layer from something that has really run. A pattern is a record of what worked, not a guess.
