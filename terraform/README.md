# Terraform

## Local S3 buckets

`local-s3-buckets/` manages buckets on Versity Gateway. It uses the
`hashicorp/aws` provider with a custom, path-style S3 endpoint. This allows
Terraform to manage S3 bucket resources, bucket policies, and static website
configuration through Versity's S3-compatible API.

Versity account identities and access keys are outside the S3 API. Manage those
through Versity's own admin API/CLI instead.

Versity does not currently implement the S3 bucket lifecycle API. The former
Mimir rule that expired all objects after 90 days therefore remains deferred;
do not add `aws_s3_bucket_lifecycle_configuration` until Versity supports both
reading and writing that configuration.

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

## Cloud backups

`cloud-backups/` is still a dormant audit trail and needs a separate rewrite
before it can manage resources against Versity.
