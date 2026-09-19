terraform {
backend "s3" {
bucket = "backend-bucket-634541169891-us-east-1-an"
key = "terraform.tfstate"
region = "us-east-1"
use-lockfile = true
}
}
