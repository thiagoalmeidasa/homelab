provider "minio" {
  minio_server   = trimsuffix(trimprefix(var.s3_endpoint, "https://"), "/")
  minio_region   = var.s3_region
  minio_user     = var.access_key
  minio_password = var.secret_key
  minio_ssl      = true
  s3_compat_mode = true
}
