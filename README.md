# k8s-cluster

The primary repository defining the `k8s-scots-lab` bare-metal Kubernetes cluster, provisioned via **Sidero Omni** and **Talos Linux**.

[![Generate K8s Manifests](https://github.com/ghubprime/k8s-cluster/actions/workflows/generate.yml/badge.svg)](https://github.com/ghubprime/k8s-cluster/actions/workflows/generate.yml)

## Architecture

```
┌─────────────────────────────────────────────────┐
│  k8s-cluster.yaml (Omni Cluster Template)       │
│  ├─ Talos v1.12.6 / Kubernetes v1.35.2          │
│  ├─ 3x ODROID H4 Ultra (ControlPlane)           │
│  └─ extraManifests → bootstrap/                 │
│       ├─ Multus CNI                             │
│       ├─ Gateway API CRDs                       │
│       ├─ ArgoCD                                 │
│       └─ ArgoCD App-of-Apps (48 applications)  │
└─────────────────────────────────────────────────┘
         │
         ▼  omnictl cluster template sync
┌─────────────────────────────────────────────────┐
│  GitHub Actions CI Pipeline                     │
│  ├─ Kustomize v5.4.3 + Helm v3.12.0            │
│  ├─ generate-manifests.sh --force               │
│  └─ Commits rendered output to manifests/       │
└─────────────────────────────────────────────────┘
         │
         ▼  ArgoCD syncs from manifests/
┌─────────────────────────────────────────────────┐
│  Live Cluster (48 ArgoCD Applications)          │
│  Wave -1: CRDs (Gateway API, kGateway)          │
│  Wave  0: Infra (Cilium, Multus, Whereabouts)   │
│  Wave  1: Core (ArgoCD, cert-manager, Ceph,     │
│           Metrics Server, Velero, SealedSecrets) │
│           CrowdSec, Cloudflare)                  │
│  Wave  2: Services (Ceph Cluster, kGateway)     │
│  Wave  3: Apps & Monitoring (kube-prometheus...) │
└─────────────────────────────────────────────────┘
```

## Repository Structure

```
k8s-cluster/
├── k8s-cluster.yaml        # Omni Cluster Template (Talos + K8s config)
├── generate-manifests.sh    # Manifest generation script (CI only — never run on Windows)
│
├── bootstrap/               # extraManifests patches for Omni template
│   └── k8s-cluster-extramanifests-*.yaml
│
├── kustomize/
│   ├── base/                # Base Kustomize resources per app
│   └── overlays/scots-lab/  # Environment-specific overlays and patches
│       ├── apps/            # ArgoCD, cert-manager, velero, sealed-secrets
│       ├── cluster/         # rook-ceph-cluster, kgateway, gateway-api
│       ├── infra/           # Cilium, Multus, Whereabouts, Metrics Server
│       ├── monitoring/      # kube-prometheus-stack
│       └── security/        # CrowdSec
│
├── helm/
│   ├── base/                # Base HelmChartInflationGenerator definitions
│   └── overlays/scots-lab/  # Environment-specific Helm values
│
├── charts/                  # Offline Helm chart cache (CRITICAL — do not modify)
│   ├── argo-cd-*/           # ArgoCD chart
│   ├── crowdsec-*/          # CrowdSec chart

│
└── .github/workflows/
    └── generate.yml         # CI pipeline: Kustomize + Helm → manifests/
```

## CI Pipeline

On every push to `main`, the GitHub Actions pipeline:

1. Checks out the repository with full history
2. Installs **Helm v3.12.0** and **Kustomize v5.4.3** (pinned versions — see below)
3. Runs `generate-manifests.sh --force` to render all Kustomize overlays
4. Commits the rendered manifests back to the `manifests/` directory

> **⚠️ Critical**: Do **NOT** run `generate-manifests.sh` on Windows. A Kustomize binary bug causes Helm to receive `-c` as a flag, silently deleting output directories. Push raw overlays to GitHub and let CI handle generation.

### Dual-Generation Architecture

| Strategy | Used For | Mechanism |
|----------|----------|-----------|
| Legacy `HelmChartInflationGenerator` | Most apps (Velero, ArgoCD, cert-manager, etc.) | Custom generator script in `generate-manifests.sh` |
| Native Kustomize `helmCharts:` | Complex nested charts (kube-prometheus-stack) | Declarative YAML block in `kustomization.yaml` |

### Offline Chart Cache

Some charts are cached locally in `charts/` to bypass CI network restrictions. **Never** delete `Chart.yaml` or structural files from these directories — it causes silent 0-byte manifest failures.

## Prerequisites

To interact with this repository's deployed cluster:

| Tool | Location | Purpose |
|------|----------|---------|
| `kubectl` | `cluster-auth/kubectl.exe` | Kubernetes CLI |
| `omnictl` | `cluster-auth/omnictl.exe` | Omni platform management |
| `talosctl` | `cluster-auth/talosctl.exe` | Talos OS management |
| `kubeseal` | `cluster-auth/kubeseal.exe` | SealedSecrets encryption |

## Related

- **[omni-infra](https://github.com/ghubprime/omni-infra)**: Shared infrastructure repo (machine patches, network config)