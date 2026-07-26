#!/usr/bin/env bash
# Monitor Cilium policy-drop events for a specific pod
# Usage: ./hacks/cilium-drops.sh <namespace> <pod-name> [duration-seconds]
set -euo pipefail

NAMESPACE="${1:?Usage: $0 <namespace> <pod-name> [duration-seconds]}"
POD="${2:?Usage: $0 <namespace> <pod-name> [duration-seconds]}"
DURATION="${3:-20}"

echo "Looking up pod ${NAMESPACE}/${POD}..."
NODE=$(kubectl get pod -n "${NAMESPACE}" "${POD}" -o jsonpath='{.spec.nodeName}')
POD_IP=$(kubectl get pod -n "${NAMESPACE}" "${POD}" -o jsonpath='{.status.podIP}')
CONTAINERS=$(kubectl get pod -n "${NAMESPACE}" "${POD}" -o jsonpath='{.spec.containers[*].name}')
INIT_CONTAINERS=$(kubectl get pod -n "${NAMESPACE}" "${POD}" -o jsonpath='{.spec.initContainers[*].name}' || true)

if [[ -z "${NODE}" || -z "${POD_IP}" ]]; then
  echo "ERROR: could not determine node or pod IP — is the pod running?" >&2
  exit 1
fi

CONTAINER_INFO="Containers: ${CONTAINERS}"
[[ -n "${INIT_CONTAINERS}" ]] && CONTAINER_INFO+="  Init: ${INIT_CONTAINERS}"
echo "Pod IP: ${POD_IP}  Node: ${NODE}  ${CONTAINER_INFO}"

CILIUM_POD=$(kubectl get pods -n kube-system -l k8s-app=cilium -o wide \
  | awk -v node="${NODE}" '$7 == node {print $1}')

if [[ -z "${CILIUM_POD}" ]]; then
  echo "ERROR: no cilium pod found on node ${NODE}" >&2
  exit 1
fi

echo "Cilium agent: ${CILIUM_POD}"

ENDPOINT_ID=$(kubectl exec -n kube-system "${CILIUM_POD}" -- \
  cilium endpoint list \
  | awk -v ip="${POD_IP}" '$0 ~ ip {print $1; exit}' \
  || true)

if [[ -z "${ENDPOINT_ID}" ]]; then
  echo "ERROR: could not find cilium endpoint for pod IP ${POD_IP}" >&2
  exit 1
fi

echo "Endpoint ID: ${ENDPOINT_ID}"
echo "Monitoring drop events for ${DURATION}s..."
echo

kubectl exec -n kube-system "${CILIUM_POD}" -- \
  timeout "${DURATION}" cilium-dbg monitor --type drop --related-to "${ENDPOINT_ID}" \
  || true
