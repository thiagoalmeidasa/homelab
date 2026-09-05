# The MinIO provider cannot refresh its IAM and lifecycle resources against
# Versity. Forget the legacy objects without sending delete requests.
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
