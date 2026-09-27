terraform {
  backend "s3" {
    bucket = "sentinel-tfstate-amr2026"
    key    = "sentinel/terraform.tfstate"
    region = "us-east-1"
  }
}
