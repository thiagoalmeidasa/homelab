# VersityGW website hosting

VersityGW serves S3 buckets as static websites. This document defines the
supported public hostname design and the procedure for publishing a site. See
[Networking](./NETWORKING.md) for the DNS, Cloudflare Tunnel, Gateway, and TLS
architecture underneath it.

## Hostname design

VersityGW runs a dedicated website listener on port `8090` with:

```text
--website :8090
--website-domain sites.thiagoalmeida.xyz
```

At the Versity endpoint, the host maps to a bucket as follows:

```text
example-site.sites.thiagoalmeida.xyz -> bucket example-site
```

The native Versity hostname is not published directly. Cloudflare Universal
SSL on a normal full zone covers `*.thiagoalmeida.xyz`, not the deeper
`*.sites.thiagoalmeida.xyz`. Publishing the native hostname would therefore
fail TLS at the Cloudflare edge before the request reached the tunnel.

To use Universal SSL and keep the existing Versity mapping unchanged, publish
each website through an exact first-level hostname and rewrite the upstream
hostname inside Cilium:

```text
Visitor:  example-site.thiagoalmeida.xyz
                         |
                         | HTTPRoute URLRewrite
                         v
Versity:  example-site.sites.thiagoalmeida.xyz
                         |
                         v
Bucket:   example-site
```

This design has these properties:

- The public hostname is covered by Cloudflare Universal SSL.
- Versity continues using `sites.thiagoalmeida.xyz` as its website domain.
- Every published site is explicit and reviewable in Git.
- Existing public application routes and the public error-page catch-all remain
  unchanged.
- Adding a bucket does not publish it automatically; a site HTTPRoute is also
  required.

## Naming rules

Use the same value for the bucket name and the first label of the public
hostname. A site bucket must:

- Be a valid S3 bucket name and DNS label.
- Use lowercase letters, digits, and hyphens.
- Not contain dots; the route template assumes one DNS label.
- Not collide with an existing public hostname such as `media`, `photos`,
  `auth`, or `analytics`.

For example, bucket `example-site` is published as
`https://example-site.thiagoalmeida.xyz`.

The currently published site is:

| Bucket | Public URL |
| --- | --- |
| `iaghoephahsohl2fe3xahngiev8poe7u` | `https://iaghoephahsohl2fe3xahngiev8poe7u.thiagoalmeida.xyz` |

Inventory existing public hostnames before choosing a name:

```sh
rg '\$\{PUBLIC_DOMAIN\}' kubernetes/apps -g '*.yaml'
```

## Prerequisites

- AWS CLI configured with credentials authorized to manage the bucket.
- LAN access to the internal S3 API at `https://s3.${SECRET_DOMAIN}`.
- A built static site directory, called `dist/` in the examples.
- Write access to this Git repository so Flux can deploy the site route.

Do not put access keys in a manifest, command history, or this documentation.
Use an AWS CLI profile or an existing secret-management workflow.

## 1. Create and configure the bucket

Set reusable, non-secret shell variables:

```sh
export AWS_PROFILE=versity-site-publisher
export AWS_ENDPOINT_URL="https://s3.${SECRET_DOMAIN}"
export SITE_BUCKET=example-site
```

Create the bucket:

```sh
aws s3api create-bucket --bucket "${SITE_BUCKET}"
```

Enable website behavior with an index document and an optional error document:

```sh
aws s3api put-bucket-website \
  --bucket "${SITE_BUCKET}" \
  --website-configuration \
  '{"IndexDocument":{"Suffix":"index.html"},"ErrorDocument":{"Key":"error.html"}}'
```

The filenames are case-sensitive. Omit `ErrorDocument` if the build does not
produce `error.html`.

Grant anonymous read access, which the public website endpoint requires:

```sh
aws s3api put-bucket-acl \
  --bucket "${SITE_BUCKET}" \
  --acl public-read
```

`public-read-write` must never be used for a website bucket. If the site must
not be public, do not use this hosting path; put an authenticated application
or access layer in front of it instead.

Inspect the resulting settings:

```sh
aws s3api get-bucket-website --bucket "${SITE_BUCKET}"
aws s3api get-bucket-acl --bucket "${SITE_BUCKET}"
```

## 2. Upload the site

Synchronize the built files:

```sh
aws s3 sync ./dist "s3://${SITE_BUCKET}/" --delete
```

`--delete` makes the bucket mirror `dist/` and removes objects no longer in the
build. Omit it for the first diagnostic upload if deletions are undesirable.

Verify the expected objects exist:

```sh
aws s3 ls "s3://${SITE_BUCKET}/" --recursive
```

At minimum, the root should contain the configured index document.

## 3. Add an exact public HTTPRoute

Create
`kubernetes/apps/storage/versitygw/app/site-example-site.yaml`, replacing every
`example-site` occurrence with the bucket name:

```yaml
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: versity-site-example-site
  namespace: storage
spec:
  parentRefs:
    - name: external
      namespace: networking
      sectionName: https
  hostnames:
    - "example-site.${PUBLIC_DOMAIN}"
  rules:
    - filters:
        - type: URLRewrite
          urlRewrite:
            hostname: "example-site.sites.${PUBLIC_DOMAIN}"
      backendRefs:
        - name: versitygw
          port: 8090
```

The external hostname is exact rather than wildcard. Gateway API therefore
prefers this route over the existing wildcard error-page route. The
`URLRewrite` changes the upstream `Host` header so Versity selects the
`example-site` bucket.

Add the file to
`kubernetes/apps/storage/versitygw/app/kustomization.yaml`:

```yaml
resources:
  - ./versitygw.sops.yaml
  - ./helmrelease.yaml
  - ./site-example-site.yaml
```

Use a separate HTTPRoute file for every published website. This makes each
public exposure independently reviewable and removable.

## 4. Validate and deploy

Validate the repository before committing:

```sh
task validate
```

Commit and push the bucket's HTTPRoute and kustomization change. Flux normally
reconciles within its configured interval. To request immediate reconciliation
when needed:

```sh
flux reconcile source git home-kubernetes -n flux-system
flux reconcile kustomization cluster-apps -n flux-system --with-source
```

Confirm that the route was accepted:

```sh
kubectl -n storage get httproute versity-site-example-site
kubectl -n storage describe httproute versity-site-example-site
```

The `external` parent should report both `Accepted=True` and
`ResolvedRefs=True`.

## 5. Verify publication

ExternalDNS derives an exact proxied Cloudflare record from the new HTTPRoute.
It targets `ingress.thiagoalmeida.xyz`, which leads to the named Tunnel.

Check controller activity and DNS:

```sh
kubectl -n networking logs deploy/external-dns --since=15m
dig example-site.thiagoalmeida.xyz
```

Because the record is proxied, `dig` normally returns Cloudflare addresses
rather than exposing the CNAME chain.

Check visitor-facing TLS and content:

```sh
openssl s_client \
  -connect example-site.thiagoalmeida.xyz:443 \
  -servername example-site.thiagoalmeida.xyz </dev/null

curl --fail --show-error --location \
  https://example-site.thiagoalmeida.xyz/
```

The edge certificate should cover `*.thiagoalmeida.xyz`, and the response body
should be the bucket's `index.html`.

LAN clients intentionally use this same Cloudflare path. The site hostname is
not added to OpenWrt split DNS because the route is attached only to the
external Gateway.

## Updating a site

For content-only releases, rebuild and synchronize the bucket:

```sh
aws s3 sync ./dist "s3://${SITE_BUCKET}/" --delete
```

No Kubernetes or DNS change is required while the bucket and public hostname
remain the same. Cloudflare may continue serving cacheable objects after an
upload. Use versioned asset filenames or the project's established Cloudflare
cache-purge workflow when an immediate replacement is required.

Run `put-bucket-website` again when changing the index document, error document,
or routing rules. These settings are stored with the bucket rather than in the
HTTPRoute.

## Unpublishing a site

To stop public routing without deleting content:

1. Remove the site's HTTPRoute from the VersityGW kustomization.
2. Delete its manifest from Git.
3. Commit and let Flux prune the route.
4. Confirm ExternalDNS removes the owned Cloudflare record.

Removing the route is reversible. Deleting bucket contents or the bucket is a
separate, destructive action and is not part of unpublishing.

## Troubleshooting

### Browser reports a certificate or cipher mismatch

Confirm the requested hostname is the first-level public name:

```text
example-site.thiagoalmeida.xyz          supported by Universal SSL
example-site.sites.thiagoalmeida.xyz    requires deeper edge TLS coverage
```

Then inspect the certificate with `openssl s_client`. A cert-manager origin
certificate cannot fix a missing Cloudflare edge certificate.

### DNS does not resolve

Check that the HTTPRoute is accepted and inspect ExternalDNS logs. Verify that
the route references `external`, uses `sectionName: https`, and contains the
exact `${PUBLIC_DOMAIN}` hostname.

### The error page is returned

The wildcard error route handled the request because the exact site route did
not match. Check for spelling differences between:

- The browser hostname.
- `spec.hostnames` in the HTTPRoute.
- The deployed, Flux-substituted HTTPRoute.

### Versity returns a missing bucket or website error

Check the `URLRewrite` hostname. Its first label before
`.sites.thiagoalmeida.xyz` must exactly equal the bucket name. Then verify the
bucket website settings and object list:

```sh
aws s3api get-bucket-website --bucket "${SITE_BUCKET}"
aws s3 ls "s3://${SITE_BUCKET}/" --recursive
kubectl -n storage logs deploy/versitygw --since=15m
```

### Access is denied

Inspect the bucket ACL and any bucket policy. Anonymous website requests need
read permission. Grant `public-read`, never `public-read-write`.

### Gateway returns 503

Check the generated Service and its endpoints:

```sh
kubectl -n storage get service versitygw
kubectl -n storage get endpointslice \
  -l kubernetes.io/service-name=versitygw
kubectl -n storage get pods
```

Also confirm that backend port `8090` exists on the Service.

### Updated content is stale

Fetch a unique URL or inspect response cache headers to distinguish Versity
from Cloudflare caching:

```sh
curl -I "https://example-site.thiagoalmeida.xyz/?check=$(date +%s)"
```

If the current object is present through the internal S3 API but the public
response is stale, purge the relevant Cloudflare URL or deploy fingerprinted
asset filenames.

## External references

- [VersityGW global website options](https://github.com/versity/versitygw/wiki/Global-Options)
- [VersityGW S3 client configuration](https://github.com/versity/versitygw/wiki/S3-Client-Configuration)
- [Gateway API URL rewrites](https://gateway-api.sigs.k8s.io/guides/user-guides/http-redirect-rewrite/)
- [ExternalDNS Gateway API source](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/sources/gateway-api.md)
- [Cloudflare Universal SSL limitations](https://developers.cloudflare.com/ssl/edge-certificates/universal-ssl/limitations/)
