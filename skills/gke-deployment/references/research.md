# GKE Deployment Best Practices Research

> Comprehensive research on Google Kubernetes Engine deployment patterns, configurations, and production-ready practices.

---

## Deployment Strategies

### Rolling Update (Default)

The default strategy that gradually replaces old pods with new ones.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired count during update
      maxUnavailable: 0  # Zero downtime - always keep all pods running
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v1.2.3
        ports:
        - containerPort: 8080
```

**Best Practices:**
- Set `maxUnavailable: 0` for zero-downtime deployments
- Use `maxSurge: 25%` for faster rollouts with spare capacity
- Always specify resource requests/limits for predictable scheduling

### Blue-Green Deployment

Run two identical environments, switch traffic atomically.

```yaml
# Blue deployment (current production)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-blue
  labels:
    app: my-app
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
      version: blue
  template:
    metadata:
      labels:
        app: my-app
        version: blue
    spec:
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v1.0.0
---
# Green deployment (new version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-green
  labels:
    app: my-app
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
      version: green
  template:
    metadata:
      labels:
        app: my-app
        version: green
    spec:
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v2.0.0
---
# Service switches between blue/green
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
    version: blue  # Change to 'green' to switch traffic
  ports:
  - port: 80
    targetPort: 8080
```

### Canary Deployment

Gradually shift traffic to new version.

```yaml
# Stable deployment (90% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: my-app
      track: stable
  template:
    metadata:
      labels:
        app: my-app
        track: stable
    spec:
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v1.0.0
---
# Canary deployment (10% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
      track: canary
  template:
    metadata:
      labels:
        app: my-app
        track: canary
    spec:
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v2.0.0
---
# Service routes to both (traffic split by replica ratio)
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app  # Matches both stable and canary
  ports:
  - port: 80
    targetPort: 8080
```

---

## Service Types

### ClusterIP (Default)

Internal cluster communication only.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP  # Default, can be omitted
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
```

**Use when:**
- Internal microservice communication
- Database connections within cluster
- Services that don't need external access

### NodePort

Exposes service on each node's IP at a static port.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-nodeport
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # Optional: auto-assigned if omitted (30000-32767)
```

**Use when:**
- Development/testing environments
- Direct node access needed
- Custom load balancer in front

### LoadBalancer

Creates external GCP load balancer.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-lb
  annotations:
    # Use internal load balancer (VPC only)
    networking.gke.io/load-balancer-type: "Internal"
    # Or for external (default behavior, annotation optional)
    # cloud.google.com/load-balancer-type: "External"
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
  # Optional: preserve client source IP
  externalTrafficPolicy: Local
```

**Use when:**
- Simple external access needed
- Single service exposure
- L4 load balancing sufficient

### Headless Service

For StatefulSets and direct pod DNS.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-db-headless
spec:
  clusterIP: None  # Makes it headless
  selector:
    app: my-db
  ports:
  - port: 5432
```

**Use when:**
- StatefulSet pod discovery
- Client-side load balancing
- Direct pod-to-pod communication

---

## Ingress Configuration

### GKE Ingress with GCP Load Balancer

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    # Use GKE Ingress controller
    kubernetes.io/ingress.class: "gce"
    # Enable HTTPS redirect
    kubernetes.io/ingress.allow-http: "false"
    # Static IP (must be pre-created)
    kubernetes.io/ingress.global-static-ip-name: "my-static-ip"
    # Managed SSL certificate
    networking.gke.io/managed-certificates: "my-cert"
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /v1/*
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-v1
            port:
              number: 80
      - path: /v2/*
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-v2
            port:
              number: 80
  - host: www.example.com
    http:
      paths:
      - path: /*
        pathType: ImplementationSpecific
        backend:
          service:
            name: frontend
            port:
              number: 80
```

### GKE Managed Certificate

```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: my-cert
spec:
  domains:
  - api.example.com
  - www.example.com
```

### Backend Config (Health Checks, CDN, IAP)

```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: my-backend-config
spec:
  healthCheck:
    checkIntervalSec: 15
    timeoutSec: 5
    healthyThreshold: 2
    unhealthyThreshold: 3
    type: HTTP
    requestPath: /healthz
    port: 8080
  cdn:
    enabled: true
    cachePolicy:
      includeHost: true
      includeProtocol: true
      includeQueryString: false
  connectionDraining:
    drainingTimeoutSec: 60
  timeoutSec: 30
---
# Link BackendConfig to Service
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    cloud.google.com/backend-config: '{"default": "my-backend-config"}'
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
```

---

## Horizontal Pod Autoscaler (HPA)

### CPU-Based Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

### Memory and Custom Metrics

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  # Custom metric from Stackdriver/Cloud Monitoring
  - type: External
    external:
      metric:
        name: pubsub.googleapis.com|subscription|num_undelivered_messages
        selector:
          matchLabels:
            resource.labels.subscription_id: my-subscription
      target:
        type: AverageValue
        averageValue: 100
```

---

## Resource Requests and Limits

### Best Practices Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v1.0.0
        resources:
          requests:
            cpu: 100m      # 0.1 CPU cores
            memory: 256Mi  # 256 MiB
          limits:
            cpu: 500m      # 0.5 CPU cores (can burst to this)
            memory: 512Mi  # Hard limit - OOMKilled if exceeded
```

### Resource Guidelines

| Workload Type | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------------|-------------|-----------|----------------|--------------|
| Web API | 100m-500m | 1000m | 256Mi-512Mi | 1Gi |
| Worker | 250m-1000m | 2000m | 512Mi-1Gi | 2Gi |
| Database | 500m-2000m | 4000m | 1Gi-4Gi | 8Gi |
| Sidecar | 10m-50m | 100m | 32Mi-64Mi | 128Mi |

### LimitRange for Namespace Defaults

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 256Mi
    type: Container
```

### ResourceQuota for Namespace Limits

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
  namespace: production
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    pods: "50"
    services: "10"
    secrets: "20"
    configmaps: "20"
```

---

## Health Probes

### Complete Probe Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v1.0.0
        ports:
        - containerPort: 8080
        
        # Startup probe - only runs once at startup
        # Prevents liveness probe from killing slow-starting containers
        startupProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30  # 30 * 10s = 5 minutes max startup time
        
        # Liveness probe - restarts container if it fails
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 15
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness probe - removes from service if it fails
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
          successThreshold: 1
```

### Probe Types

**HTTP Probe:**
```yaml
httpGet:
  path: /healthz
  port: 8080
  httpHeaders:
  - name: X-Custom-Header
    value: probe
```

**TCP Probe:**
```yaml
tcpSocket:
  port: 5432
```

**Exec Probe:**
```yaml
exec:
  command:
  - /bin/sh
  - -c
  - pg_isready -U postgres
```

**gRPC Probe:**
```yaml
grpc:
  port: 50051
  service: my.health.Service  # Optional
```

### Probe Best Practices

| Probe | Purpose | Failure Action | Recommended Settings |
|-------|---------|----------------|----------------------|
| Startup | Wait for app to start | Block liveness/readiness | failureThreshold: 30, periodSeconds: 10 |
| Liveness | Detect deadlocks | Restart container | periodSeconds: 15, failureThreshold: 3 |
| Readiness | Control traffic | Remove from service | periodSeconds: 5, failureThreshold: 3 |

---

## ConfigMaps and Secrets

### ConfigMap for Application Config

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  # Simple key-value
  LOG_LEVEL: "info"
  API_TIMEOUT: "30s"
  
  # Multi-line config file
  application.yaml: |
    server:
      port: 8080
    logging:
      level: INFO
    features:
      enabled:
        - feature-a
        - feature-b
```

### Using ConfigMap in Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v1.0.0
        
        # Environment variables from ConfigMap
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: my-app-config
              key: LOG_LEVEL
        
        # All keys as environment variables
        envFrom:
        - configMapRef:
            name: my-app-config
        
        # Mount as files
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
          readOnly: true
      
      volumes:
      - name: config-volume
        configMap:
          name: my-app-config
          items:
          - key: application.yaml
            path: application.yaml
```

### Secrets Management

```yaml
# Create secret from literal (in practice, use External Secrets Operator or Sealed Secrets)
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secrets
type: Opaque
stringData:  # Use stringData for plain text (auto-encoded)
  DATABASE_URL: "postgres://user:pass@host:5432/db"
  API_KEY: "secret-api-key"
---
# Using in Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: my-app-secrets
              key: DATABASE_URL
```

### Workload Identity for GCP Services

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  annotations:
    iam.gke.io/gcp-service-account: my-app@my-project.iam.gserviceaccount.com
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: my-app-sa
      containers:
      - name: my-app
        image: gcr.io/my-project/my-app:v1.0.0
```

---

## Namespace Organization

### Recommended Namespace Structure

```yaml
# Environment-based namespaces
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    env: production
    team: platform
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    env: staging
    team: platform
---
# Team/Service-based namespaces
apiVersion: v1
kind: Namespace
metadata:
  name: team-payments
  labels:
    team: payments
    cost-center: cc-1234
```

### Namespace Patterns

| Pattern | Use Case | Example |
|---------|----------|---------|
| Environment | Strict env isolation | `production`, `staging`, `dev` |
| Team | Team ownership | `team-payments`, `team-users` |
| Service | Microservice isolation | `service-api`, `service-worker` |
| Hybrid | Env + Service | `prod-api`, `staging-api` |

---

## Labeling Standards

### Recommended Labels

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    # Kubernetes recommended labels
    app.kubernetes.io/name: my-app
    app.kubernetes.io/instance: my-app-production
    app.kubernetes.io/version: "1.2.3"
    app.kubernetes.io/component: api
    app.kubernetes.io/part-of: my-platform
    app.kubernetes.io/managed-by: helm
    
    # Custom organizational labels
    team: platform
    cost-center: cc-1234
    environment: production
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: my-app
      app.kubernetes.io/instance: my-app-production
  template:
    metadata:
      labels:
        app.kubernetes.io/name: my-app
        app.kubernetes.io/instance: my-app-production
        app.kubernetes.io/version: "1.2.3"
```

### Label Usage Matrix

| Label | Purpose | Example Values |
|-------|---------|----------------|
| `app.kubernetes.io/name` | Application name | `nginx`, `my-api` |
| `app.kubernetes.io/instance` | Unique instance | `my-api-prod` |
| `app.kubernetes.io/version` | App version | `1.2.3` |
| `app.kubernetes.io/component` | Component type | `frontend`, `backend`, `database` |
| `app.kubernetes.io/part-of` | Parent application | `my-platform` |
| `team` | Owning team | `platform`, `payments` |
| `environment` | Deploy environment | `production`, `staging` |

---

## Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2  # OR use maxUnavailable: 1
  selector:
    matchLabels:
      app: my-app
```

---

## Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          env: production
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:  # Allow DNS
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

---

## Complete Production Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-api
  labels:
    app.kubernetes.io/name: my-api
    app.kubernetes.io/version: "1.2.3"
    app.kubernetes.io/component: api
    team: platform
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app.kubernetes.io/name: my-api
  template:
    metadata:
      labels:
        app.kubernetes.io/name: my-api
        app.kubernetes.io/version: "1.2.3"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: my-api-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      
      containers:
      - name: my-api
        image: gcr.io/my-project/my-api:1.2.3
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
        - name: metrics
          containerPort: 9090
        
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: my-api-config
              key: LOG_LEVEL
        
        envFrom:
        - secretRef:
            name: my-api-secrets
        
        startupProbe:
          httpGet:
            path: /healthz
            port: http
          periodSeconds: 10
          failureThreshold: 30
        
        livenessProbe:
          httpGet:
            path: /healthz
            port: http
          periodSeconds: 15
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          periodSeconds: 5
          failureThreshold: 3
        
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: config
          mountPath: /etc/config
          readOnly: true
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: config
        configMap:
          name: my-api-config
      
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: my-api
              topologyKey: kubernetes.io/hostname
      
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: my-api
```

---

## Key Takeaways

1. **Always set resource requests/limits** - Enables proper scheduling and prevents noisy neighbors
2. **Use all three probe types** - Startup, liveness, and readiness serve different purposes
3. **Configure HPA behavior** - Prevent flapping with stabilization windows
4. **Use Workload Identity** - Never store GCP credentials in Secrets
5. **Apply PodDisruptionBudgets** - Ensure availability during node maintenance
6. **Follow labeling conventions** - Enable proper resource management and cost allocation
7. **Use BackendConfig** - Fine-tune GCP load balancer behavior
8. **Implement Network Policies** - Defense in depth for production workloads
