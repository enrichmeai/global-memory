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
- **APIs enabled by Terraform** (`run`, `artifactregistry`, `secretmanager`, `iam`), so a fresh project works.
- **Startup probe sized for a JVM:** up to 4 minutes (48 × 5 s) before the instance is given up on.

## What varies per use
- `project_id`, `region`, `service_name`, `image` and `invokers`, in `terraform.tfvars` (not committed).
- The secrets list, and the env var each one appears as.
- The memory and CPU limits.

## How to use it (first deploy)
Cloud Run needs the image and each secret's value to exist before the service can start, so the
first deploy has three steps. A later deploy only builds and pushes a new tag (step 2's second
half) and applies it (step 3). Secrets are added once, and again only when one changes.

1. **Bootstrap.** In `infra/`, run `terraform init`, then
   `terraform apply -target=google_project_service.apis -target=google_artifact_registry_repository.images -target=google_secret_manager_secret.secret`.
   This enables the APIs and creates the image repository and the (empty) secrets. On a brand-new
   project, Terraform's own calls need the Service Usage API (and sometimes Cloud Resource Manager)
   enabled first: `gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com`.
   API enabling takes effect gradually, so a first apply that fails on a just-enabled API usually
   passes when rerun a minute later.
2. **Fill them.**
   - Add each secret's value once, outside Terraform: `printf %s "$VALUE" | gcloud secrets versions add NAME --data-file=-`.
   - Let Docker push to Artifact Registry once: `gcloud auth configure-docker REGION-docker.pkg.dev`.
   - Build and push the image (`terraform output image_repository` gives the repository):
     `docker build --platform linux/amd64 -t REGION-docker.pkg.dev/PROJECT/SERVICE/SERVICE:TAG .`
     then `docker push REGION-docker.pkg.dev/PROJECT/SERVICE/SERVICE:TAG`.
3. **Deploy.** `terraform apply`, with `image` set to that tag.

`deletion_protection` defaults to true. Set it to false and apply before `terraform destroy`.

## Check
`check.sh` runs `terraform fmt -check`, then `terraform init -backend=false` and `terraform validate`
(both need the provider registry). It then builds the language layer with this Dockerfile and
**runs** the image, checking that it runs as a non-root user, listens on `PORT`, and answers
`/actuator/health/readiness` and `/liveness` with 200, which are the facts the Cloud Run probes rely on.
Whatever this machine can't run is reported as SKIP. `GM_REQUIRE_ALL=1` (set in CI) turns a SKIP into a failure.
