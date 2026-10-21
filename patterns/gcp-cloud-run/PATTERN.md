# gcp-cloud-run

The cloud layer for a stateless HTTP service on Google Cloud: a container image in Artifact
Registry, run on Cloud Run as its own service account, with secrets from Secret Manager, all
in Terraform. It fits on top of `java21-spring-boot` (and `rest-service`); the Dockerfile
builds any Gradle Spring Boot service.

## When it applies
- A stateless API or web service, deployed per region, that should scale to zero when idle.

## When it does not
- Data that must live on a disk next to the service (a database, a Solid pod): use a VM with a
  persistent disk, or a managed database, instead.
- Long-running background work over many minutes: Cloud Run jobs or a worker layer fit better.

## The decisions and why
- **A multi-stage Dockerfile.** The build runs in a Gradle + JDK 21 image. The runtime is a
  JRE 21 image running as a non-root user, with only the one Boot jar (the language layer turns
  off the plain jar). `-XX:MaxRAMPercentage` sizes the heap to the container.
- **Its own service account** with only the roles it needs, never the default compute account.
- **Secrets from Secret Manager by reference** (`value_source.secret_key_ref`). Values never sit
  in Terraform, the image or the environment of a CI job. Terraform creates the secret, not its value.
- **Private by default.** `ingress = INGRESS_TRAFFIC_ALL`, but only the principals in `invokers`
  may call it. Opening it to `allUsers` is a deliberate change of one variable.
- **Health from actuator:** startup and liveness probes on `/actuator/health/*`. The language layer
  enables the probe groups and reads `PORT`.
- **Scaling bounds as variables:** `min_instances = 0` (scale to zero), with a ceiling against runaway cost.

## What varies per use
- `project_id`, `region`, `service_name`, `image` and `invokers`, in `terraform.tfvars` (not committed).
- The secrets list, and the env var each one appears as.
- The memory and CPU limits.

## How to use it
1. Build and push: `docker build -t REGION-docker.pkg.dev/PROJECT/REPO/SERVICE:TAG .` then `docker push`.
2. `terraform init`, then `terraform apply` in `infra/`.
3. Add each secret's value once, outside Terraform: `gcloud secrets versions add NAME --data-file=-`.

## Check
`check.sh` runs `terraform fmt -check`, then `terraform init -backend=false` and `terraform validate`
(both need the provider registry), then a `docker build` of the language layer with this Dockerfile.
Whatever this machine can't run is reported as SKIP. `GM_REQUIRE_ALL=1` (set in CI) turns a SKIP into a failure.
