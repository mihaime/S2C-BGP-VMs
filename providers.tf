provider "google" {
  project = "prjbetaaviatrixgcp"
  region  = "europe-west3"
}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_access
  secret_key = var.aws_secret
}

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
  client_id       = var.azure_appId
  client_secret   = var.azure_password
  tenant_id       = var.azure_tenant
}
