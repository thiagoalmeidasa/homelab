# Terraform — dormant, needs rewrite

## Status

`terraform/local-s3-buckets/` and `terraform/cloud-backups/` are **dormant**
post-RustFS/MinIO decommission. They use the `aminueza/minio` provider, which
speaks MinIO's admin API and is **incompatible with Versity** (the current S3
backend).

- **State backend**: works against Versity. The `terraform-state` bucket lives
  on Versity, owned by the `terraform` user. `terraform init` succeeds and the
  state file loads correctly.
- **Provider (resource refresh / plan / apply)**: does not work. Versity has
  no Terraform provider — IAM and bucket lifecycle is managed via the
  `versitygw admin` CLI directly.

The modules are kept as a frozen audit trail of what the MinIO-era resources
looked like. Do not run `terraform apply`.

## Credentials

- Backend (state R/W): Versity user `terraform`. Bitwarden item
  `minio-tf-creds` needs to be updated with the Versity creds before any
  `terraform init` will succeed in the future. Format unchanged:
  ```
  access_key = "..."
  secret_key = "..."
  ```
- Provider: the variables (`minio_user`, `minio_password`) still default to
  MinIO. They no longer resolve to anything live.

## TODO

- [ ] Decide: rewrite both modules using `null_resource` + `local-exec` calls
      to `versitygw admin user/bucket` and `aws s3 mb` for buckets, OR delete
      the modules entirely and manage Versity IAM ad-hoc via the CLI.
- [ ] If keeping: update `provider.tf` / `variables.tf` to drop the MinIO
      provider, and rewrite `cnpg.tf` / `mimir.tf` against the chosen
      replacement.
- [ ] If deleting: also drop the `terraform-state` bucket on Versity and the
      `terraform` user.

See PR that introduced this README for the RustFS+MinIO decommission and the
state-backend migration to Versity.
