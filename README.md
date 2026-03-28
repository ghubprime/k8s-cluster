# k8s-cluster
The primary repository defining the `k8s-scots-lab` bare-metal Kubernetes cluster, provisioned via Sidero Omni and Talos Linux.

## Repository Overview
This repository contains the authoritative cluster definition (`k8s-cluster.yaml`) and the primary GitOps structure driving ArgoCD for cluster deployment and base applications. 

### Key Components
- `k8s-cluster.yaml`: The primary Omni Cluster template defining the Talos machine templates, Kubernetes configurations, and initial bootstrap manifests.
- `bootstrap/`: Consolidated bootstrap manifests (`_bootstrap.yaml` per app) referenced by `k8s-cluster.yaml` during cluster instantiation. Each file is a single concatenated YAML containing all resources for one bootstrap component (Multus, Gateway API CRDs, ArgoCD, ArgoCD Apps).
- `kustomize/overlays/scots-lab/`: Contains the Kustomize overlays and configurations for all core infrastructure apps deployed internally within the cluster.
- `helm/overlays/scots-lab/`: Environment-specific Helm values for applications managed via Kustomize HelmChartInflationGenerator (e.g., Velero, ArgoCD Apps).
- `manifests/`: Final static GitOps payloads rendered directly from CI. ArgoCD syncs exclusively from this directory.
- `helm/`: Environment-specific properties and Kustomize overrides defining customized application values.
- `charts/`: The vital **offline cache directory**. Highly-constrained dependencies (like Vaultwarden/ArgoCD) are pulled here natively. The raw `Chart.yaml` descriptors within this folder MUST NOT be structurally modified or deleted, or Kustomize generator pipelines will throw silent 0-byte panics.
- `generate-manifests.sh`: Shell script automation for generating rendered manifests and consolidated bootstrap files. Driven entirely by the GitHub Actions pipeline upon commit. Manual generation locally is obsolete.