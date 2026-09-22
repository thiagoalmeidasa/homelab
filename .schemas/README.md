# Custom Kubernetes schemas

The schemas in this directory cover CRDs that are not yet available from the
configured public catalogs.

`http.keda.sh/interceptorroute_v1beta1.json` is generated from the KEDA HTTP
add-on CRD installed in the current Kubernetes cluster:

```sh
task schema:update
```

Add CRD names to the `CRDS` array in `hacks/update-flux-schemas.sh` to extend
the local catalog.
