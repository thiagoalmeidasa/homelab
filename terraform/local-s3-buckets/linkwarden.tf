# Bucket
resource "minio_s3_bucket" "linkwarden" {
  bucket = "linkwarden"
  acl    = "private"
}

# Service account with scoped policy
resource "minio_iam_user" "linkwarden" {
  name = "linkwarden"
}

resource "minio_iam_policy" "linkwarden" {
  name = "linkwarden-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
      ]
      Resource = [
        "arn:aws:s3:::linkwarden",
        "arn:aws:s3:::linkwarden/*",
      ]
    }]
  })
}

resource "minio_iam_user_policy_attachment" "linkwarden" {
  user_name   = minio_iam_user.linkwarden.name
  policy_name = minio_iam_policy.linkwarden.name
}

# Expire all objects after 180 days
resource "minio_ilm_policy" "linkwarden" {
  bucket = minio_s3_bucket.linkwarden.bucket

  rule {
    id         = "expire-all-180d"
    expiration = "180d"
    filter     = ""
  }
}

# Output the access key for use in SOPS secrets
resource "minio_iam_service_account" "linkwarden" {
  target_user = minio_iam_user.linkwarden.name
}

output "linkwarden_access_key" {
  value = minio_iam_service_account.linkwarden.access_key
}

output "linkwarden_secret_key" {
  value     = minio_iam_service_account.linkwarden.secret_key
  sensitive = true
}
