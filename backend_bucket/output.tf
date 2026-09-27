output "backend_bucket_name" {
  description = "Bucket name of backend bucket"
  value = aws_s3_bucket.example.id
}
