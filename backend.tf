terraform {
backend "s3" {
bucket = "backend-bucket-968894489489-us-east-1-an"
key = "terraform.tfstate"
region = "us-east-1"
use_lockfile = true
}
}
