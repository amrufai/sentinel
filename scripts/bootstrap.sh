#!/usr/bin/env bash
# Sentinel platform bootstrap — GitHub Codespaces (k3d). Idempotent: safe to re-run.
set -euo pipefail

echo "==> [1/7] k3d cluster"
k3d cluster get sentinel >/dev/null 2>&1 || \
  k3d cluster create sentinel --servers 1 --agents 0 --k3s-arg "--disable=traefik@server:0" --wait

echo "==> [2/7] helm repos"
helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null 2>&1 || true
helm repo add external-secrets https://charts.external-secrets.io >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

echo "==> [3/7] patched CRDs + Helm ownership tags"
kubectl apply --server-side --force-conflicts -f bootstrap/crds/kyverno-crds.yaml
kubectl apply --server-side --force-conflicts -f bootstrap/crds/eso-crds.yaml
kubectl get crd -o name | grep -E "kyverno|wgpolicyk8s" | xargs -r -I{} kubectl annotate {} meta.helm.sh/release-name=kyverno meta.helm.sh/release-namespace=kyverno --overwrite
kubectl get crd -o name | grep -E "kyverno|wgpolicyk8s" | xargs -r -I{} kubectl label {} app.kubernetes.io/managed-by=Helm --overwrite
kubectl get crd -o name | grep external-secrets | xargs -r -I{} kubectl annotate {} meta.helm.sh/release-name=external-secrets meta.helm.sh/release-namespace=external-secrets --overwrite
kubectl get crd -o name | grep external-secrets | xargs -r -I{} kubectl label {} app.kubernetes.io/managed-by=Helm --overwrite

echo "==> [4/7] helm releases (skips anything already installed)"
helm list -n kyverno | grep -q kyverno || helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set crds.install=false \
  --set admissionController.resources.requests.cpu=50m --set admissionController.resources.requests.memory=128Mi \
  --set admissionController.resources.limits.cpu=300m --set admissionController.resources.limits.memory=384Mi
helm list -n external-secrets | grep -q external-secrets || helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --skip-crds --set installCRDs=false
helm list -n monitoring | grep -q monitoring || helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  --set grafana.adminPassword=admin123 --set alertmanager.enabled=false \
  --set prometheus.prometheusSpec.retention=6h \
  --set prometheus.prometheusSpec.resources.requests.memory=512Mi \
  --set prometheus.prometheusSpec.resources.limits.memory=1Gi

echo "==> [5/7] argo rollouts v1.7.2 (annotation-size-safe version)"
kubectl get ns argo-rollouts >/dev/null 2>&1 || kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/v1.7.2/install.yaml

echo "==> [6/7] argocd + application"
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--load-restrictor LoadRestrictionsNone"}}'
kubectl apply -f infra/argocd/argocd-application.yaml || true

echo "==> [7/7] cluster state"
kubectl get pods -A
echo "Next: add prom-client, build v5.0.0, import, push."
