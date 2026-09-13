/* 
 * Der Terraform Block definiert die grundlegenden Voraussetzungen für dieses Projekt.
 * Er schützt davor, dass jemand mit einer veralteten Terraform-Version den State (Zustand) beschädigt.
 */
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      # Gibt die offizielle Quelle des AWS-Providers an (Terraform Registry)
      source  = "hashicorp/aws"
      # Die Tilde-Gleich-Schreibweise (~> 5.0) bedeutet: 
      # Erlaube alle Minor-Updates (z.B. 5.1, 5.2), aber KEIN Major-Update (6.0),
      # da Major-Updates oft "Breaking Changes" enthalten, die den Code unbrauchbar machen könnten.
      version = "~> 5.0"
    }
  }
}

/* 
 * Der Provider-Block konfiguriert das eigentliche Plugin, das mit der AWS API spricht.
 */
provider "aws" {
  # Die Region wird dynamisch aus der variables.tf geladen. 
  # So lässt sich die gesamte Infrastruktur leicht global verschieben.
  region = var.region
}