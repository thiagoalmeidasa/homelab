# Bucket
resource "minio_s3_bucket" "mimir" {
  bucket = "mimir"
  acl    = "private"
}

# Service account with scoped policy
resource "minio_iam_user" "mimir" {
  name = "mimir"
}

resource "minio_iam_policy" "mimir" {
  name = "mimir-policy"
  policy = jsonencode({
    ID      = ""
    Version = "2012-10-17"
    Statement = [{
      Sid    = ""
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:GetBucketLocation",
      ]
      Resource = [
        "arn:aws:s3:::mimir/*",
        "arn:aws:s3:::mimir",
      ]
      Condition = {}
    }]
  })
}

resource "minio_iam_user_policy_attachment" "mimir" {
  user_name   = minio_iam_user.mimir.name
  policy_name = minio_iam_policy.mimir.name
}

# Expire all objects after 90 days
resource "minio_ilm_policy" "mimir" {
  bucket = minio_s3_bucket.mimir.bucket

  rule {
    id         = "expire-all-90d"
    expiration = "90d"
    filter     = ""
  }
}

# Output the access key for use in SOPS secrets
resource "minio_iam_service_account" "mimir" {
  target_user = minio_iam_user.mimir.name
}

output "mimir_access_key" {
  value = minio_iam_service_account.mimir.access_key
}

output "mimir_secret_key" {
  value     = minio_iam_service_account.mimir.secret_key
  sensitive = true
}
