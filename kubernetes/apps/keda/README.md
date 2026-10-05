# KEDA

[KEDA](https://keda.sh/) is an event-driven autoscaler for Kubernetes. This directory deploys KEDA core plus the [KEDA HTTP add-on](https://github.com/kedacore/http-add-on), which together provide scale-to-zero (and back up) for HTTP workloads.

Everything here is managed by Flux. Two HelmReleases make up the stack:

| Component | Chart | Version | Notes |
|-----------|-------|---------|-------|
| [keda](keda/app/helmrelease.yaml) | `keda` | 2.21.0 | KEDA core (operator, metrics server) |
| [http-add-on](http-add-on/app/helmrelease.yaml) | `keda-add-ons-http` | 0.16.0 | Interceptor, external scaler, operator |

The HTTP add-on interceptor is pinned to exactly 2 replicas (`interceptor.replicas.min: 2`, `max: 2`).

## How HTTP scale-to-zero works

```
client ──► Gateway ──► HTTPRoute ──► interceptor-proxy (keda ns) ──► your app (0..N replicas)
                                          │
                                          ▼
                              external-scaler ──► ScaledObject on your app
```

When a request arrives for a host the interceptor knows about, it forwards it and reports the pending-request count to the external scaler. The `ScaledObject` on the target workload then scales it up from zero. When traffic stops, the workload scales back down after the cooldown period.

Three resources are involved per app:

1. **HTTPRoute** (in the app's namespace) routes the app's hostname to the `keda-add-ons-http-interceptor-proxy` Service in the `keda` namespace. Cross-namespace backend refs require a `ReferenceGrant` — the add-on ships grants for the `home`, `monitoring`, and `default` namespaces in [referencegrants.yaml](http-add-on/app/referencegrants.yaml). Add one for any new namespace.
2. **InterceptorRoute** (`http.keda.sh/v1beta1`) maps the hostname to the target Service and configures the scaling metric, cold-start overflow, and timeouts.
3. **ScaledObject** with an `external-push` trigger pointing at the external scaler and referencing the `InterceptorRoute` by name, with `minReplicaCount: 0` for scale-to-zero.

## Current usage

These apps scale to zero on idle HTTP traffic:

- [openspeedtest](../../default/openspeedtest/app/autoscaling.yaml)
- [home-assistant-v2-code-server](../../home/home-assistant-v2/app/autoscaling.yaml)

## Example: scale to zero with HTTP

Modeled on the headlamp setup. Drop this next to the app's HelmRelease and add it to the app's `kustomization.yaml` resources.

```yaml
---
apiVersion: http.keda.sh/v1beta1
kind: InterceptorRout
metadata:
  name: myapp
  namespace: default
spec:
  target:
    service: myapp
    port: 80
  rules:
    - hosts:
        - "myapp.${SECRET_DOMAIN}"
  scalingMetric:
    concurrency:
      targetValue: 10      # scale up when more than 10 concurrent requests per replica
  coldStart:
    maxPendingRequests: 100 # queue (or reject) requests while the app starts
    overflow: Reject
  timeouts:
    readiness: 2m          # how long a cold-start may take
    request: 3m
    responseHeader: 2m
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: myapp
  namespace: default
spec:
  scaleTargetRef:
    name: myapp
  pollingInterval: 5
  cooldownPeriod: 600      # scale down 10 minutes after the last request
  minReplicaCount: 0       # scale to zero
  maxReplicaCount: 1
  advanced:
    restoreToOriginalReplicaCount: true
  triggers:
    - type: external-push
      metadata:
        scalerAddress: keda-add-ons-http-external-scaler.keda.svc.cluster.local:9090
        interceptorRoute: myapp # must match the InterceptorRoute name
```

You also need an HTTPRoute that sends the app's hostname to the interceptor:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: myapp
  namespace: default
spec:
  parentRefs:
    - name: internal
      namespace: networking
  hostnames:
    - "myapp.${SECRET_DOMAIN}"
  rules:
    - backendRefs:
        - name: keda-add-ons-http-interceptor-proxy
          namespace: keda
          port: 8080
```

And, if the app lives outside `home`/`monitoring`/`default`, a `ReferenceGrant` allowing that namespace's HTTPRoutes to reach the interceptor (copy [referencegrants.yaml](http-add-on/app/referencegrants.yaml)).

## References

- [KEDA ScaledObject spec](https://keda.sh/docs/latest/reference/scaledobject-spec/)
- [KEDA HTTP add-on](https://keda.sh/docs/latest/http-add-on/)
- [HTTP add-on InterceptorRoute / CRD reference](https://github.com/kedacore/http-add-on)
