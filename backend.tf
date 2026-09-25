terraform {
backend "s3" {
bucket = "backend-bucket-381491944316-us-east-1-an"
key = "terraform.tfstate"
region = "us-east-1"
use_lockfile = true
}
}
