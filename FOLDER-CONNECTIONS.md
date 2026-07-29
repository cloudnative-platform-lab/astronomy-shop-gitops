# Folder Connections

This repository has one job: turn approved Git changes into Kubernetes workload changes through Argo CD.

```text
astronomy-shop-gitops/
│
├── argocd/
│   └── appsets/
│       ├── dev/
│       │   ├── project.yaml
│       │   │   └── defines what dev-generated applications may create in namespace `dev`
│       │   └── services.yaml
│       │       └── reads each service's dev values file and generates nine Argo Applications
│       ├── staging/
│       │   ├── project.yaml
│       │   │   └── allows only staging namespace workload resources
│       │   └── services.yaml
│       │       └── generates nine staging Argo Applications
│       └── prod/
│           ├── project.yaml
│           │   └── allows only prod namespace workload resources
│           └── services.yaml
│               └── generates nine production Argo Applications
│
├── charts/
│   └── astronomy-shop-service/
│       ├── Chart.yaml
│       │   └── identifies the reusable Helm chart
│       ├── values.yaml
│       │   └── safe shared defaults; environment files override these values
│       └── templates/
│           ├── _helpers.tpl
│           │   └── creates stable names, labels, and digest-first image reference
│           ├── deployment.yaml
│           │   └── creates a Deployment for rolling-update services
│           ├── rollout.yaml
│           │   └── creates an Argo Rollout for canary services
│           ├── service.yaml
│           │   └── creates stable internal DNS: <service>.<namespace>.svc
│           ├── hpa.yaml
│           │   └── scales pods; Argo ignores replica-count drift caused by HPA
│           ├── networkpolicy.yaml
│           │   └── limits inbound traffic to the service port
│           ├── servicemonitor.yaml
│           │   └── lets Prometheus scrape /metrics when monitoring is enabled
│           ├── analysis-template.yaml
│           │   └── supplies optional Prometheus checks to a canary rollout
│           └── ingress.yaml
│               └── disabled by default because Terraform owns the single ALB Ingress
│
└── helm-values/
    ├── dev/
    │   └── <service>-values.yaml
    │       └── dev image digest, small capacity, rolling update, telemetry disabled
    ├── staging/
    │   └── <service>-values.yaml
    │       └── promoted image digest, moderate capacity, canary, telemetry enabled
    └── prod/
        └── <service>-values.yaml
            └── promoted image digest, higher capacity, longer canary, telemetry enabled
```

## Exact connection for one service

`frontend-proxy` is an example; every other service follows the same route.

```text
helm-values/dev/frontend-proxy-values.yaml
  -> argocd/appsets/dev/services.yaml list generator item: frontend-proxy
  -> generated Argo Application: frontend-proxy-dev
  -> chart path: charts/astronomy-shop-service
  -> Helm creates the frontend-proxy Service, stable/canary Services, Rollout, and the public ALB Ingress in namespace dev
  -> AWS Load Balancer Controller reconciles that GitOps-managed Ingress and sends public traffic to frontend-proxy-stable:8080
  -> frontend-proxy uses values to reach frontend:8080 and image-provider:8081 internally
```

## What connects from other repositories

```text
astronomy-shop-app
  GitHub Actions
    -> Amazon ECR: astronomy-shop/<service>
    -> commits image repository + tag + digest into this repo's helm-values files

astronomy-shop-infrastructure
  Terraform platform/<environment>
    -> installs Argo CD and controllers
    -> creates namespaces and service accounts
    -> creates the root Argo CD Application targeting argocd/appsets/<environment>
    -> installs the AWS Load Balancer Controller that reconciles the GitOps-managed ALB Ingress

astronomy-shop-gitops
  Argo CD reconciliation
    -> reads AppProject and ApplicationSet
    -> renders the shared chart with one environment/service values file
    -> creates or updates Kubernetes workloads
```

## Rules that prevent wiring mistakes

1. Keep values-file names exactly `<service>-values.yaml`; application CI already uses this format.
2. Keep `service.name` equal to the service name—not `<service>-dev` or `<service>-prod`.
3. Put environment differences in namespaces and values files, not in service DNS names.
4. Enable Helm Ingress only for `frontend-proxy`; it is the sole internet-facing workload. Keep every backend Ingress disabled.
5. Use image digests for deployments. Tags are helpful labels but not the deployment identity.
6. Keep `astronomy-shop-runtime` as a required Secret for `cart` and `image-provider`; it is supplied by External Secrets from AWS Secrets Manager.
7. Add database credentials only to the service that actually uses PostgreSQL after its source code confirms the required environment variable names.
8. Do not enable dev metrics/tracing flags until their controllers/backends exist in the dev cluster.
