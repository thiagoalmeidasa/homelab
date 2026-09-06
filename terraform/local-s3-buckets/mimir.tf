resource "aws_s3_bucket" "mimir" {
  bucket = "mimir"
}

data "aws_iam_policy_document" "mimir" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["mimir"]
    }

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.mimir.arn]
  }

  statement {
    sid    = "ObjectAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["mimir"]
    }

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.mimir.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "mimir" {
  bucket = aws_s3_bucket.mimir.id
  policy = data.aws_iam_policy_document.mimir.json
}
