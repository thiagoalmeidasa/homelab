resource "minio_s3_bucket" "mimir" {
  bucket = "mimir"
  acl    = "private"
}
