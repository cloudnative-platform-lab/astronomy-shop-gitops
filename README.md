# Astronomy Shop GitOps

This repository is the Kubernetes delivery source of truth. Terraform installs the cluster, controllers, namespaces, service accounts, and the root Argo CD Application. Argo CD then reads this repository and continuously reconciles the application workloads.

## Repository layout

```text
astronomy-shop-gitops/
├── argocd/
│   └── appsets/
│       ├── dev/
│       │   ├── project.yaml       # AppProject: only dev namespace workload resources
│       │   └── services.yaml      # ApplicationSet: one Argo Application per service
│       ├── staging/
│       └── prod/
├── charts/
│   └── astronomy-shop-service/
│       ├── Chart.yaml             # shared Helm chart metadata
│       ├── values.yaml            # safe chart defaults
│       └── templates/             # Deployment/Rollout, Service, HPA, policy, telemetry
└── helm-values/
    ├── dev/                       # low-cost values; telemetry disabled until installed
    ├── staging/                   # production-like canary values
    └── prod/                      # stronger capacity and longer canary pauses
```

## Delivery wiring

```text
astronomy-shop-app GitHub Actions
  -> pushes a scanned/signed image to shared Amazon ECR
  -> writes repository, tag, and immutable digest to helm-values/<environment>/<service>-values.yaml
  -> commits to this repository
  -> Argo CD root Application reads argocd/appsets/<environment>
  -> ApplicationSet creates one Argo CD Application per service
  -> generated Application renders charts/astronomy-shop-service
  -> Helm combines values.yaml + the matching helm-values file
  -> Kubernetes Deployment or Argo Rollout is reconciled in its environment namespace
```

The chart uses the service name without an environment suffix. The namespace supplies environment isolation, so `frontend` resolves to `frontend.dev.svc.cluster.local` in dev and `frontend.prod.svc.cluster.local` in prod. This also keeps the Terraform-managed ALB target `frontend-proxy:8080` correct.

## Important ownership boundaries

Terraform owns the EKS cluster, namespaces, service accounts, AWS Load Balancer Controller, External Secrets, Argo CD installation, root Application, and AWS resources.

Argo CD owns the AppProjects, ApplicationSets, generated Applications, Helm-rendered workloads, HPA, NetworkPolicy, ServiceMonitor, and optional Argo Rollout/AnalysisTemplate objects.

Application CI owns only immutable image fields in `helm-values/<environment>/<service>-values.yaml`. It must not modify Helm templates or unrelated environment settings automatically.

## Image rule

Every values file contains `image.repository`, `image.tag`, and `image.digest`. The digest is authoritative. The chart uses `repository@digest` whenever a digest is present, preventing a mutable tag from silently changing the deployed image.

Do not enable the Terraform GitOps root Application until every required dev values file has a real repository and digest.

## Repository access

Argo CD reads this private repository with a dedicated read-only SSH deploy key:

```text
git@github.com:cloudnative-platform-lab/astronomy-shop-gitops.git
```

The application CI workflow uses a separate GitHub token with write access only to this repository. Never store either private key or token in this repository.

See [FOLDER-CONNECTIONS.md](FOLDER-CONNECTIONS.md) for the detailed folder-by-folder explanation.
