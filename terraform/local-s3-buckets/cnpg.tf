resource "aws_s3_bucket" "cnpg_backups" {
  bucket = "cnpg-backups"
}

data "aws_iam_policy_document" "cnpg_backup" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["cnpg-backup"]
    }

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.cnpg_backups.arn]
  }

  statement {
    sid    = "ObjectAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["cnpg-backup"]
    }

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.cnpg_backups.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "cnpg_backup" {
  bucket = aws_s3_bucket.cnpg_backups.id
  policy = data.aws_iam_policy_document.cnpg_backup.json
}
