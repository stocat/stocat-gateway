# stocat-app Helm chart (generic)

Reusable Helm chart that renders a single Deployment (fixed 1 replica), a Service, and an optional HTTPRoute based on minimal values. Defaults are sensible to reduce overrides.

Prerequisites
- Kubernetes cluster (kind OK)
- Helm 3
- Consul installed and reachable at the address provided in `values.yaml` (default `consul-server.consul.svc:8500`)
- App images accessible by the cluster (for kind, load local images)

1) Build container images

```bash
./gradlew :services:demo-catalog:bootBuil****dImage \
          :services:demo-order:bootBuildImage \
          :gateway:bootBuildImage
```

Default image tags
- demo-catalog: `demo-catalog:0.0.1-SNAPSHOT`
- demo-order: `demo-order:0.0.1-SNAPSHOT`
- gateway: `gateway:0.0.1-SNAPSHOT`

2) For kind, load images into the cluster

```bash
kind load docker-image demo-catalog:0.0.1-SNAPSHOT --name stocat
kind load docker-image demo-order:0.0.1-SNAPSHOT --name stocat
kind load docker-image gateway:0.0.1-SNAPSHOT --name stocat
```

3) (Optional) Install Consul (if your apps use it)

```bash
kubectl create namespace consul || true
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install consul hashicorp/consul \
  --namespace consul \
  --set global.name=consul \
  --set server.replicas=1 \
  --set ui.enabled=true
```

4) (Optional) Seed Consul KV manually if your apps require it (example for this repo’s gateway)

```bash
kubectl -n consul port-forward svc/consul-server 8500:8500 &

curl --request PUT --data-binary "replace-with-a-strong-secret-32-bytes-min" \
  http://localhost:8500/v1/kv/config/common/secrets/jwt-secret

# Optional: routes.yaml
cat <<'YAML' | curl --request PUT --data-binary @- \
  http://localhost:8500/v1/kv/config/gateway/routes.yaml
spring:
  cloud:
    gateway:
      server:
        webflux:
          discovery:
            locator:
              enabled: false
          routes:
            - id: catalog
              uri: lb://demo-catalog
              predicates:
                - Path=/catalog/**
              filters:
                - StripPrefix=1

            - id: order
              uri: lb://demo-order
              predicates:
                - Path=/order/**
              filters:
                - StripPrefix=1
YAML
```

5) Install the chart

```bash
helm install stocat ./helm/stocat-gateway -n stocat --create-namespace
kubectl -n stocat get pods,svc
```

6) Test routing (example from this repo)

```bash
kubectl -n stocat port-forward svc/stocat-gateway-gateway 8080:8080
curl -i http://localhost:8080/catalog/actuator/health
curl -i http://localhost:8080/order/actuator/health
```

Customize values (minimal)

```yaml
imagePullPolicy: IfNotPresent

global:
  labels: {}
  annotations: {}
  env: []
  consul:
    enabled: true
    host: consul-server.consul.svc
    port: 8500

image:
  repository: gateway
  tag: 0.0.1-SNAPSHOT

containerPort: 8080
service:
  enabled: true
  type: NodePort   # or ClusterIP
  port: 8080

httpRoute:
  enabled: false
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
  hostnames: ["localhost"]
  pathPrefixes: ["/"]
  # backendPort: 8080  # defaults to service.port
```

Notes
- Deployment replicas are fixed at 1 by design for this chart.
- Gateway API CRDs and a Gateway object are required to use HTTPRoutes.
- For external access, use NodePort or HTTPRoute to a Gateway.
- Ensure image names match those loaded into kind.
- Toggle global Consul env injection with `global.consul.enabled`.
