# java21-spring-boot

The language layer of global memory: a Java 21 Spring Boot service, built with Gradle,
that starts, answers a health check and has one test proving it. Every other Java layer
(`rest-service`, the cloud layers) is written to sit on top of this one.

## When it applies
- A new JVM service or tool, or a repository that has drifted and needs a known-good base.

## When it does not
- A library with no runtime: drop the Boot plugin and keep `java-library`.
- A function too small to justify Spring: plain Java with no framework is cheaper to run.

## The decisions and why
- **Java 21 through the Gradle toolchain**, not whatever JDK is on the machine, so CI and
  laptops build the same thing.
- **Spring Boot 3.5 with the dependency-management plugin**, so starter versions come from
  Boot's bill of materials and are never pinned one by one.
- **Starters: web, validation, actuator.** Actuator gives `/actuator/health` for load
  balancers and Cloud Run. Only `health` and `info` are exposed.
- **`server.port: ${PORT:8080}`.** Cloud Run and most platforms pass the port in `PORT`.
- **Graceful shutdown**, so a deploy lets in-flight requests finish.
- **One test that boots the context and calls health.** It is the cheapest proof that the
  wiring works, and the first thing to fail when it doesn't.

## What varies per use
- `rootProject.name` in `settings.gradle`, and the package `com.example.app`. Rename both.
- Extra starters (data, security). Add them to `build.gradle` without versions.

## Check
`check.sh` copies the skeleton to a temporary directory and runs `gradle test`
(`GM_GRADLE_OFFLINE=1` adds `--offline` where dependencies are already cached).
