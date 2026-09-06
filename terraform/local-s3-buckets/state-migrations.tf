# Versity does not implement the MinIO admin API. Forget the legacy MinIO
# objects without sending delete requests. The S3 buckets are imported below
# at their equivalent AWS provider addresses.
removed {
  from = minio_s3_bucket.cnpg_backups

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_s3_bucket.mimir

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_s3_bucket.thiagoalmeida_xyz

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_iam_policy.cnpg_backup

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_iam_policy.mimir

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_iam_service_account.cnpg

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_iam_service_account.mimir

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_iam_user.cnpg

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_iam_user.mimir

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_iam_user_policy_attachment.cnpg

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_iam_user_policy_attachment.mimir

  lifecycle {
    destroy = false
  }
}

removed {
  from = minio_ilm_policy.mimir

  lifecycle {
    destroy = false
  }
}

import {
  to = aws_s3_bucket.cnpg_backups
  id = "cnpg-backups"
}

import {
  to = aws_s3_bucket.mimir
  id = "mimir"
}

import {
  to = aws_s3_bucket.thiagoalmeida_xyz
  id = "thiagoalmeida-xyz"
}

import {
  to = aws_s3_bucket.website
  id = "iaghoephahsohl2fe3xahngiev8poe7u"
}

import {
  to = aws_s3_bucket_website_configuration.website
  id = "iaghoephahsohl2fe3xahngiev8poe7u"
}

import {
  to = aws_s3_bucket_policy.website
  id = "iaghoephahsohl2fe3xahngiev8poe7u"
}
