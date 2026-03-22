# k8s-cluster
The primary repository defining the `k8s-scots-lab` bare-metal Kubernetes cluster, provisioned via Sidero Omni and Talos Linux.

## Repository Overview
This repository contains the authoritative cluster definition (`k8s-cluster.yaml`) and the primary GitOps structure driving ArgoCD for cluster deployment and base applications. 

### Key Components
- `k8s-cluster.yaml`: The primary Omni Cluster template defining the Talos machine templates, Kubernetes configurations, and initial bootstrap manifests.
- `bootstrap/`: Initial CRDs, Multus CNI manifests, Gateway API components, and ArgoCD baseline manifests referenced directly by the Omni `k8s-cluster.yaml` during cluster instantiation.
- `kustomize/overlays/scots-lab/`: Contains the Kustomize overlays and configurations for all core infrastructure apps deployed internally within the cluster.
- `manifests/`, `helm/`, `charts/`: Additional configuration and packaged deployments mapped via Kustomize.
- `generate-manifests.sh`: Shell script automation utility for generating dependent resources.