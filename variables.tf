/*
 * Variablen zentralisieren Werte, die mehrfach im Code vorkommen.
 * Das verhindert Tippfehler und erleichtert spätere Anpassungen.
 */

variable "region" {
  description = "Die physische AWS-Region."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Ein Präfix für alle erstellten Ressourcen."
  type        = string
  default     = "cloud-portfolio"
}

variable "vpc_cidr" {
  description = "Das Classless Inter-Domain Routing (CIDR) für das Hauptnetzwerk."
  type        = string
  default     = "10.0.0.0/16"
}