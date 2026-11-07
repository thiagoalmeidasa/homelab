# Forgejo CI jobs with a per-job Docker daemon

Jobs on the `docker-amd64` / `docker-arm64` workflow labels get their own
ephemeral Docker daemon as a **native sidecar** in the job pod (an
initContainer with `restartPolicy: Always`, `docker:29-dind`, privileged).
The job container talks to it over localhost with mTLS; nothing is shared
between jobs.

> Scope: the dind sidecar is privileged and runs only trusted jobs. Isolation
> between CI jobs comes from each job having its own daemon — there is no
> shared mutable image store.

## Why two labels

A Docker daemon can only *run* containers of its own CPU architecture, so the
labels are arch-pinned via `nodeSelector` — the whole job pod (including the
sidecar) lands on a native node of that arch. No binfmt handler is installed
anywhere in this stack: a wrong-arch image fails with `exec format error`
instead of silently emulating. That failure is expected; pick the other label.

## What is already set up in a job

The podspec sets these for you:

| Env var | Value |
| ------- | ----- |
| `DOCKER_HOST` | `tcp://localhost:2376` |
| `DOCKER_TLS_VERIFY` | `1` |
| `DOCKER_CERT_PATH` | `/certs/client` |

The `dind` sidecar starts before the job container (a startupProbe waits for
`docker info`), so `docker` works immediately in a step. Storage at
`/var/lib/docker` is an `emptyDir`: every job starts with a cold image store —
expect the first pull of every image to hit the registry. The daemon and
everything it ran disappear when the job pod is deleted, so containers cannot
leak across jobs and testcontainers Ryuk can stay enabled.

## Usage

```sh
docker info            # daemon is ready when the job starts
docker run --rm alpine uname -m   # x86_64 on docker-amd64, aarch64 on docker-arm64
```

For testcontainers, no configuration is needed — it reads `DOCKER_HOST`.
Images under test must match the job's architecture.

## Relationship to remote BuildKit

Image *builds* still go through the per-arch remote builders (see
[FORGEJO_BUILDS.md](FORGEJO_BUILDS.md)); the dind sidecar is only for running
containers. If you build inside a dind job anyway (embedded BuildKit), that's
also native — but there is no persistent build cache, and `--load` loads into
the job-local store only.

## Verification

```sh
# job pods have 2/2 containers Ready; the sidecar passed its startupProbe
kubectl -n forgejo get pods -l app.kubernetes.io/managed-by=forgejo-runner

# from a docker-amd64 job: wrong-arch image must fail (no QEMU)
docker run --rm arm64v8/alpine true   # exec format error — expected
docker run --rm alpine uname -m       # x86_64
```

## Operations notes

| Condition | Symptom | Recovery |
| --------- | ------- | -------- |
| Slow job start | dind init takes a few seconds | Expected — the startupProbe holds the job container until `docker info` succeeds |
| `docker` hangs at job start | startupProbe exceeded 30 s | Check node load/disk; the pod restarts the sidecar automatically |
| OOM in the sidecar | dind restarts at the 4 GiB limit during heavy pulls/runs | Retry; raise the limit only with an explicit decision |
| `exec format error` on run | Job uses an image of the other architecture | Use the matching `docker-<arch>` label; no emulation is provided by design |
