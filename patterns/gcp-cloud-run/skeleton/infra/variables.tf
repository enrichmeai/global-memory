variable "project_id" {
  type        = string
  description = "The GCP project to deploy into."
}

variable "region" {
  type        = string
  description = "Region for Cloud Run and Artifact Registry, e.g. europe-west2."
}

variable "service_name" {
  type        = string
  description = "Cloud Run service name; also names the service account and the image repository."
}

variable "image" {
  type        = string
  description = "Full image reference to run, e.g. REGION-docker.pkg.dev/PROJECT/REPO/SERVICE:TAG."
}

variable "invokers" {
  type        = list(string)
  description = "Principals allowed to call the service, e.g. [\"user:alice@example.com\"]. Empty: nobody but the project's owners."
  default     = []
}

variable "secrets" {
  type        = map(string)
  description = "Environment variable name to Secret Manager secret id. Terraform creates the secrets; their values are added outside it."
  default     = {}
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 3
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "cpu" {
  type    = string
  default = "1"
}
