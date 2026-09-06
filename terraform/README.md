# Terraform

## Local S3 buckets

`local-s3-buckets/` manages buckets on Versity Gateway. It uses the
`hashicorp/aws` provider with a custom, path-style S3 endpoint. This allows
Terraform to manage S3 bucket resources, bucket policies, and static website
configuration through Versity's S3-compatible API.

Versity account identities and access keys are outside the S3 API. Manage those
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

The first apply after this migration forgets the legacy MinIO resources from
Terraform state with `destroy = false`, then imports the existing buckets at
their AWS provider addresses. It also imports the existing website bucket,
website configuration, and bucket policy. It does not delete or recreate any
buckets.

## Cloud backups

`cloud-backups/` is still a dormant audit trail and needs a separate rewrite
before it can manage resources against Versity.
