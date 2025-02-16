resource "b2_bucket" "nas-backup-bucket" {
  bucket_name = "home399-nas-backup-bucket"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}

