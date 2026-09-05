resource "minio_s3_bucket" "thiagoalmeida_xyz" {
  bucket = "thiagoalmeida-xyz"
  acl    = "private"
}
