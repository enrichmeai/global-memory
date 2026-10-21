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
  description = "Cloud Run service name; also names the service account (<name>-run) and the image repository."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,24}[a-z0-9]$", var.service_name))
    error_message = "3 to 26 characters: lower-case letters, digits and hyphens, starting with a letter (the service account id adds -run, 30 at most)."
  }
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
  description = "Environment variable name to Secret Manager secret id. Terraform creates the secrets; their values are added outside it, before the first full apply."
  default     = {}
  validation {
    condition = alltrue([for k, s in var.secrets :
      can(regex("^[A-Z_][A-Z0-9_]*$", k)) && can(regex("^[A-Za-z0-9_-]{1,255}$", s))
    ])
    error_message = "Keys are environment variable names (A-Z, 0-9, _); values are secret ids (letters, digits, - and _)."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Refuse to destroy or replace the Cloud Run service. Set false (and apply) before terraform destroy."
  default     = true
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
  type        = string
  description = "Container memory. The JVM takes 75% of it for the heap (-XX:MaxRAMPercentage=75)."
  default     = "1Gi"
}

variable "cpu" {
  type    = string
  default = "1"
}
