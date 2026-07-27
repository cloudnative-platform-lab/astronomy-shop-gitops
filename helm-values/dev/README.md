# Dev Helm Values

One file exists per service. Application CI updates only `image.repository`, `image.tag`, and `image.digest` after a successful build pipeline.

Dev intentionally has low replica counts and disables ServiceMonitor/tracing output until the optional observability stack is installed. The chart still uses resource requests so HPA can work when Metrics Server is enabled.
