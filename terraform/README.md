# Terraform

## Local S3 buckets

`local-s3-buckets/` manages buckets on Versity Gateway. It uses the
`aminueza/minio` provider only for its S3-compatible bucket operations, with
`s3_compat_mode = true`.

Versity does not implement the MinIO admin API used by the provider's IAM and
ILM resources. Manage users, credentials, policies, and lifecycle behavior
through Versity's own admin API/CLI instead.

### Credentials

Generate the ignored `state.config` file from Bitwarden:

```shell
cd terraform/local-s3-buckets
./generate-state-config.sh
```

The file contains `access_key` and `secret_key`. Those values configure both
the S3 state backend and the bucket provider; credentials are not stored in
tracked Terraform files.

### Commands

```shell
terraform init -backend-config=state.config
terraform plan -var-file=state.config
```

The first plan after this migration forgets the legacy MinIO IAM and ILM
objects from Terraform state with `destroy = false`. It does not delete those
objects or any buckets.

## Cloud backups

`cloud-backups/` is still a dormant audit trail and needs a separate rewrite
before it can manage resources against Versity.
