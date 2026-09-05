resource "minio_s3_bucket" "cnpg_backups" {
  bucket = "cnpg-backups"
  acl    = "private"
}
