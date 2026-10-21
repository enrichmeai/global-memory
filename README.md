# global memory

**Free, verified starter patterns, so you don't need an expensive model to build and deploy an app.**

A pattern holds the know-how: the decisions already made, a skeleton that was right last time,
and a `check.sh` that says when the result works. With that in hand, a small or local model can
build and deploy a service by copying the skeleton, changing what varies, and running the check.
It doesn't have to work everything out from scratch.

A pattern is model-neutral: it records decisions, files and a check, never prompt wording. So one
pattern serves any model and any agent (Penstock, Claude Code, any MCP client, or a person),
instead of a separate "skill" kept per tool.

Global memory is the shared, public tier of an agent's memory. It sits beside your own (estate)
and your project's. A narrower tier wins: your project's pattern for the same job overrides the
global one. [Penstock](https://github.com/enrichmeai/penstock) loads these patterns on demand
(`list_patterns`, `load_pattern`) or at the start of a turn. Any agent or person can also just
read them; each one is plain files.

## Layers, not combinations

Pick one layer from each row and they compose:

| Category | Folder | Available now |
|---|---|---|
| Language and framework | `patterns/language/` | [`java21-spring-boot`](patterns/language/java21-spring-boot/) |
| Architecture | `patterns/architecture/` | [`rest-service`](patterns/architecture/rest-service/) (on top of a language layer) |
| Cloud platform | `patterns/cloud/` | [`gcp-cloud-run`](patterns/cloud/gcp-cloud-run/) |
| CI | `patterns/ci/` | [`github-actions-gradle`](patterns/ci/github-actions-gradle/) |

Every pattern sits in exactly one category folder, and its id is unique across all of them:

```
patterns/<category>/<id>/
  PATTERN.md      when it applies, when it does not, the decisions and why, what varies per use
  manifest.yaml   id, version, triggers, signatures, inputs, verified-against {tag, date}
  skeleton/       the files, with real defaults; PATTERN.md lists what to rename
  check.sh        exits 0 when the skeleton, in a clean directory, still works
```

## Rules

- **A pattern is only merged with a passing `check.sh`, and CI runs every check** with
  `GM_REQUIRE_ALL=1`, so a step that could not run is a failure there, never a silent pass.
- **Everything here is public.** No credentials, no customer specifics; each check scans its skeleton.
- **`verified-against`** names the tool and framework versions the pattern was last proven with,
  and the date.
- **Cards follow memory format v1**, the same schema as Penstock's (`check-cards.sh --root` validates them).

## Using a pattern by hand

```sh
cp -R patterns/language/java21-spring-boot/skeleton/. my-service/
cp -R patterns/architecture/rest-service/skeleton/. my-service/
cp patterns/cloud/gcp-cloud-run/skeleton/Dockerfile patterns/cloud/gcp-cloud-run/skeleton/.dockerignore my-service/
cp -R patterns/cloud/gcp-cloud-run/skeleton/infra my-service/
cp -R patterns/ci/github-actions-gradle/skeleton/.github my-service/
```

Then follow each `PATTERN.md`'s "What varies per use".

## Licence

Apache License 2.0. See [LICENSE](LICENSE).
