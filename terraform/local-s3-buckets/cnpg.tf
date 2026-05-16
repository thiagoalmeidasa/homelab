# Bucket
resource "minio_s3_bucket" "cnpg_backups" {
  bucket = "cnpg-backups"
  acl    = "private"
}

# Service account with scoped policy
resource "minio_iam_user" "cnpg" {
  name = "cnpg-backup"
}

resource "minio_iam_policy" "cnpg_backup" {
  name = "cnpg-backup-policy"
  policy = jsonencode({
    ID      = ""
    Version = "2012-10-17"
    Statement = [{
      Sid    = ""
      Effect = "Allow"
      Action = [
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
      ]
      Resource = [
        "arn:aws:s3:::cnpg-backups",
        "arn:aws:s3:::cnpg-backups/*",
      ]
      Condition = {}
    }]
  })
}

resource "minio_iam_user_policy_attachment" "cnpg" {
  user_name   = minio_iam_user.cnpg.name
  policy_name = minio_iam_policy.cnpg_backup.name
}

# Output the access key for use in SOPS secrets
resource "minio_iam_service_account" "cnpg" {
  target_user = minio_iam_user.cnpg.name
}

output "cnpg_access_key" {
  value = minio_iam_service_account.cnpg.access_key
}

output "cnpg_secret_key" {
  value     = minio_iam_service_account.cnpg.secret_key
  sensitive = true
}
