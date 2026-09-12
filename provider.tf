terraform {
  # Wir fordern eine aktuelle Terraform-Version
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Wir nutzen die AWS Provider Version 5.x für aktuelle Features
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Die Region wird aus den Variablen geladen
  region = var.region
}