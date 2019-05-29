#######################################################
#
# TERRAFORM INITIALIZATION
#
#######################################################
provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    region = "eu-central-1"
  }
}

