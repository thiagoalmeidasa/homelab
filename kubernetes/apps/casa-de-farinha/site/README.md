# Casa de Farinha (Ghost)

Ghost publication for **Casa de Farinha**, deployed with the bjw-s app-template
chart in the `casa-de-farinha` namespace.

| What | Where |
| --- | --- |
| Public site | `https://casa-de-farinha.${PUBLIC_DOMAIN}` |
| Homepage dashboard | Websites group (internal route) |

## Architecture

- **Ghost 6** (`docker.io/library/ghost`), single replica.
See the [Ghost config docs](https://docs.ghost.org/config)).
- **SQLite** database at `/var/lib/ghost/content/data/ghost.db`.
- **S3 (VersityGW)** for media and files via Ghost's built-in `S3Storage`
- **SMTP** via the cluster `smtp-relay`

## Routes and admin privacy

Two HTTPRoutes in `httproute.yaml`:

## S3 bucket setup (prerequisite)

The bucket must exist and be publicly readable before uploads work. From a
LAN host with an S3 profile (see [WEBSITE_HOSTING.md](../../docs/WEBSITE_HOSTING.md)):

```sh
export AWS_ENDPOINT_URL="https://s3.${SECRET_DOMAIN}"
export SITE_BUCKET=casa-de-farinha-ghost

aws s3api create-bucket --bucket "${SITE_BUCKET}"
aws s3api put-bucket-website --bucket "${SITE_BUCKET}" \
  --website-configuration '{"IndexDocument":{"Suffix":"index.html"}}'
aws s3api put-bucket-acl --bucket "${SITE_BUCKET}" --acl public-read
```

The public hostname comes from
`kubernetes/apps/storage/versitygw/app/site-casa-de-farinha-ghost.yaml`,
which rewrites `casa-de-farinha-ghost.${PUBLIC_DOMAIN}` to the Versity
website endpoint. ExternalDNS creates the Cloudflare record automatically.

S3 credentials live in `secret.sops.yaml` (SOPS/age encrypted); edit with
`sops`. Reloader restarts Ghost when the secret changes.
