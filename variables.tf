# variables.tf

variable "region" {
  description = "Die AWS-Region, in der die Ressourcen erstellt werden."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name des Projekts, wird für das Tagging verwendet."
  type        = string
  default     = "cloud-portfolio"
}

variable "vpc_cidr" {
  description = "Der CIDR-Block für das VPC."
  type        = string
  default     = "10.0.0.0/16"
}