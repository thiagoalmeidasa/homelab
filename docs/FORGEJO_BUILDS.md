# Forgejo native image builds with remote BuildKit

The Forgejo runner (`forgejo-runner` in the `forgejo` namespace) builds container
images on two persistent, rootless BuildKit builders — one per CPU architecture.
Jobs talk to the matching builder over mTLS with Docker Buildx's `remote` driver.
There is no Docker daemon and no Docker-in-Docker.

> Scope: builders are for trusted jobs only. Rootless mode is not a strong
> isolation boundary (see
> [rootless caveats](https://github.com/moby/buildkit/blob/master/docs/rootless.md)).
> A single shared client certificate identifies all job pods; mTLS does not
> isolate repositories from each other.

## Workflow labels and endpoints

One runner registration with capacity 2 serves all labels. Generic labels are
explicitly AMD64.

| Workflow label       | Architecture | Remote endpoint                              |
| -------------------- | ------------ | -------------------------------------------- |
| `ubuntu-latest`      | amd64        | `tcp://buildkit-amd64.forgejo.svc:1234`     |
| `ubuntu-24.04`       | amd64        | `tcp://buildkit-amd64.forgejo.svc:1234`     |
| `default`            | amd64        | `tcp://buildkit-amd64.forgejo.svc:1234`     |
| `ubuntu-24.04-amd64` | amd64        | `tcp://buildkit-amd64.forgejo.svc:1234`     |
| `ubuntu-24.04-arm64` | arm64        | `tcp://buildkit-arm64.forgejo.svc:1234`     |

The `docker` label no longer exists. Anything that needs `docker run`, Docker
Compose, service containers, or a local Docker image store is unsupported.
Do not use `--load` / default-load — there is no local image store to load into.

## Buildx setup in a job

Each job pod mounts the shared client certificate at `/certs/buildkit`
(`ca.crt`, `tls.crt`, `tls.key`) and has `BUILDKIT_HOST` set to its matching
endpoint. Create a per-job builder with the remote driver:

```sh
docker buildx create --name native --driver remote \
  --driver-opt cacert=/certs/buildkit/ca.crt,cert=/certs/buildkit/tls.crt,key=/certs/buildkit/tls.key \
  "tcp://buildkit-amd64.forgejo.svc:1234"   # or the arm64 endpoint for arm64 jobs
docker buildx inspect --bootstrap native
docker buildx build --builder native -t registry.example.com/app/image:tag --push .
```

- The remote driver needs no Docker daemon. `--bootstrap` verifies the mTLS
  connection and shows the native worker.
- Push with credentials supplied by the workflow itself (for example
  `forgejo login` + registry secret variables). There are no cluster-wide
  registry credentials.
- To export without pushing: `docker buildx build --builder native --output type=oci,dest=image.tar .`
- No emulation, no multi-node builders, no automatic multi-arch manifests:
  one builder, one native platform per job.

## Verification commands

Architecture placement and builder readiness:

```sh
kubectl -n forgejo get pods -l 'app.kubernetes.io/instance in (buildkit-amd64,buildkit-arm64)' -o wide
kubectl get nodes -L kubernetes.io/arch
kubectl -n forgejo exec buildkit-amd64-0 -- buildctl debug workers
```

Certificate status (expect `Ready=True` on all four):

```sh
kubectl -n forgejo get certificates
kubectl -n forgejo get issuer
```

Longhorn cache volumes (one replica each, 20 GiB):

```sh
kubectl -n longhorn-system get volumes
kubectl -n forgejo get pvc -l 'app.kubernetes.io/instance in (buildkit-amd64,buildkit-arm64)'
```

Cache reuse after a builder restart (re-run the same build; the cacheable step
must print `CACHED`):

```sh
kubectl -n forgejo delete pod buildkit-amd64-0   # PVC is retained
# re-submit the same build
```

Access control checks:

```sh
# allowed: a job-pod-labelled pod with /certs/buildkit mounted
kubectl -n forgejo run bk-check --rm -it --restart=Never --labels app.kubernetes.io/managed-by=forgejo-runner \
  --image ghcr.io/bjw-s-labs/forgejo-runner:ubuntu-24.04 -- \
  buildctl --addr tcp://buildkit-amd64.forgejo.svc:1234 --tlscacert /certs/buildkit/ca.crt \
  --tlscert /certs/buildkit/tls.crt --tlskey /certs/buildkit/tls.key debug workers

# rejected: same pod without client certificates -> TLS handshake failure
# blocked: any pod without the forgejo-runner managed-by label -> timeout (CiliumNetworkPolicy)
```

## Operations notes

| Condition | Symptom | Recovery |
| --------- | ------- | -------- |
| Leaf certificate renewal | Reloader should restart the affected builder; builds in flight are killed | Wait for the replacement pod to be Ready, then retry the build |
| Reloader not restarting builders (known gap) | After certificate rotation the builder keeps running with the old server certificate (clients still trust it until the certificate expires) | Manually roll the builder: `kubectl -n forgejo rollout restart statefulset buildkit-<arch>`. Automatic Reloader restarts are currently not working cluster-wide; tracked separately |
| CA rotation | Not automatic — leaf renewal does not rotate trust | Controlled migration: issue new CA, distribute overlapping trust, then retire the old CA |
| Builder pod Pending | No node with matching `kubernetes.io/arch` | Expected behavior — there is no cross-architecture fallback. Provide a node of that architecture |
| Full cache volume | Build fails with disk errors | Delete the cache PVC (an operator action) and let it rebuild cold; or expand the volume |
| OOM kill | Pod restarts at the 4 GiB memory limit during large builds | Retry; reduce build parallelism; larger limits need an explicit decision |
| mTLS failures | `tls: bad certificate` / handshake errors | Check `kubectl -n forgejo get certificate` and pod cert mounts |
| Snapshotter errors on old kernels | Rootless worker fails to start | Builders require user namespaces; check `user.max_user_namespaces` and node kernel (see rootless caveats) |

Garbage collection uses BuildKit defaults. Cache volumes use one Longhorn
replica, are not covered by backups, and are deleted with the application
unless retained intentionally.
