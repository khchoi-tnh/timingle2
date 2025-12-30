# timingle 배포 가이드

## 📋 목차

1. [배포 환경 개요](#배포-환경-개요)
2. [개발 환경 배포](#개발-환경-배포)
3. [스테이징 환경 배포](#스테이징-환경-배포)
4. [프로덕션 환경 배포](#프로덕션-환경-배포)
5. [Kubernetes 배포](#kubernetes-배포)
6. [모니터링 및 로깅](#모니터링-및-로깅)
7. [백업 및 복구](#백업-및-복구)
8. [롤백 절차](#롤백-절차)

---

## 배포 환경 개요

### 환경 구성

| 환경 | 목적 | 인프라 | URL |
|------|------|--------|-----|
| **Development** | 로컬 개발 | Podman Compose | localhost:8080 |
| **Staging** | 통합 테스트 | VM or Kubernetes | staging.timingle.com |
| **Production** | 실제 서비스 | Kubernetes (권장) | api.timingle.com |

### 배포 전략

- **개발**: 수동 배포 (Podman Compose)
- **스테이징**: CI/CD 자동 배포 (main 브랜치)
- **프로덕션**: 태그 기반 배포 (v1.0.0)

---

## 개발 환경 배포

### Podman Compose 사용

#### 1. 서비스 시작
```bash
cd containers
podman-compose up -d
```

#### 2. 상태 확인
```bash
podman-compose ps
```

#### 3. 로그 확인
```bash
podman-compose logs -f
```

#### 4. 서비스 중지
```bash
podman-compose down
```

자세한 내용은 [DEVELOPMENT.md](DEVELOPMENT.md) 참조

---

## 스테이징 환경 배포

### VM 기반 배포

#### 1. 서버 준비
```bash
# Ubuntu 22.04 LTS
sudo apt update
sudo apt install -y podman podman-compose git

# 사용자 추가
sudo useradd -m -s /bin/bash timingle
sudo usermod -aG sudo timingle
```

#### 2. 리포지토리 클론
```bash
sudo su - timingle
git clone https://github.com/yourusername/timingle2.git
cd timingle2
git checkout main
```

#### 3. 환경 변수 설정
```bash
cp .env.example .env
nano .env

# 스테이징 설정
ENV=staging
DB_PASSWORD=<strong-password>
JWT_SECRET=<random-32-char-string>
# ...
```

#### 4. 서비스 시작
```bash
cd containers
podman-compose -f podman-compose.yml -f podman-compose.staging.yml up -d
```

#### 5. 백엔드 빌드 및 실행
```bash
cd ../backend
go build -o bin/api cmd/api/main.go

# Systemd 서비스 등록
sudo nano /etc/systemd/system/timingle-api.service
```

**timingle-api.service**:
```ini
[Unit]
Description=Timingle API Server
After=network.target

[Service]
Type=simple
User=timingle
WorkingDirectory=/home/timingle/timingle2/backend
ExecStart=/home/timingle/timingle2/backend/bin/api
Restart=always
RestartSec=5
Environment="ENV=staging"

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable timingle-api
sudo systemctl start timingle-api
sudo systemctl status timingle-api
```

#### 6. Nginx 설정 (리버스 프록시)
```bash
sudo apt install -y nginx
sudo nano /etc/nginx/sites-available/timingle
```

**/etc/nginx/sites-available/timingle**:
```nginx
server {
    listen 80;
    server_name staging.timingle.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ws {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/timingle /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### 7. SSL 인증서 (Let's Encrypt)
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d staging.timingle.com
```

---

## 프로덕션 환경 배포

### 권장: Kubernetes

#### 사전 요구사항
- Kubernetes 클러스터 (GKE, EKS, AKS, or on-premise)
- `kubectl` CLI 설치
- Helm 3.x 설치

---

## Kubernetes 배포

### 1. Namespace 생성
```bash
kubectl create namespace timingle-prod
kubectl config set-context --current --namespace=timingle-prod
```

### 2. Secret 생성
```bash
# PostgreSQL
kubectl create secret generic postgres-secret \
  --from-literal=username=timingle \
  --from-literal=password=<strong-password>

# JWT
kubectl create secret generic jwt-secret \
  --from-literal=secret=<random-32-char-string>

# Google OAuth
kubectl create secret generic google-oauth \
  --from-literal=client-id=<client-id> \
  --from-literal=client-secret=<client-secret>
```

### 3. ConfigMap 생성
```bash
kubectl apply -f k8s/configmap.yaml
```

**k8s/configmap.yaml**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: timingle-config
  namespace: timingle-prod
data:
  ENV: "production"
  LOG_LEVEL: "info"
  DB_HOST: "postgres-service"
  DB_PORT: "5432"
  DB_NAME: "timingle"
  REDIS_HOST: "redis-service"
  REDIS_PORT: "6379"
  NATS_URL: "nats://nats-service:4222"
  SCYLLA_HOSTS: "scylla-service"
  SCYLLA_PORT: "9042"
```

### 4. Persistent Volume 생성

#### PostgreSQL
```yaml
# k8s/postgres-pv.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: timingle-prod
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: standard
```

#### ScyllaDB
```yaml
# k8s/scylla-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: scylla-pvc
  namespace: timingle-prod
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: fast-ssd
```

```bash
kubectl apply -f k8s/postgres-pv.yaml
kubectl apply -f k8s/scylla-pvc.yaml
```

### 5. 데이터베이스 배포

#### PostgreSQL
```yaml
# k8s/postgres-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: timingle-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: timingle
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: timingle-prod
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

#### ScyllaDB (StatefulSet)
```yaml
# k8s/scylla-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: scylla
  namespace: timingle-prod
spec:
  serviceName: scylla
  replicas: 3
  selector:
    matchLabels:
      app: scylla
  template:
    metadata:
      labels:
        app: scylla
    spec:
      containers:
      - name: scylla
        image: scylladb/scylla:5.4
        ports:
        - containerPort: 9042
          name: cql
        - containerPort: 7000
          name: intra-node
        - containerPort: 7001
          name: tls-intra-node
        - containerPort: 7199
          name: jmx
        - containerPort: 10000
          name: rest
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
          limits:
            memory: "8Gi"
            cpu: "4"
        volumeMounts:
        - name: scylla-data
          mountPath: /var/lib/scylla
  volumeClaimTemplates:
  - metadata:
      name: scylla-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 100Gi
---
apiVersion: v1
kind: Service
metadata:
  name: scylla-service
  namespace: timingle-prod
spec:
  clusterIP: None
  selector:
    app: scylla
  ports:
  - port: 9042
    name: cql
```

```bash
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/scylla-statefulset.yaml
```

### 6. Redis & NATS 배포
```yaml
# k8s/redis-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: timingle-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: timingle-prod
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
```

```yaml
# k8s/nats-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nats
  namespace: timingle-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nats
  template:
    metadata:
      labels:
        app: nats
    spec:
      containers:
      - name: nats
        image: nats:2.10-alpine
        args: ["-js", "-m", "8222"]
        ports:
        - containerPort: 4222
          name: client
        - containerPort: 8222
          name: monitoring
---
apiVersion: v1
kind: Service
metadata:
  name: nats-service
  namespace: timingle-prod
spec:
  selector:
    app: nats
  ports:
  - port: 4222
    name: client
  - port: 8222
    name: monitoring
```

```bash
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/nats-deployment.yaml
```

### 7. Backend API 배포
```yaml
# k8s/api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: timingle-api
  namespace: timingle-prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: timingle-api
  template:
    metadata:
      labels:
        app: timingle-api
    spec:
      containers:
      - name: api
        image: your-registry/timingle-api:v1.0.0
        ports:
        - containerPort: 8080
        env:
        - name: ENV
          valueFrom:
            configMapKeyRef:
              name: timingle-config
              key: ENV
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: timingle-config
              key: DB_HOST
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: secret
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: timingle-api-service
  namespace: timingle-prod
spec:
  selector:
    app: timingle-api
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

```bash
kubectl apply -f k8s/api-deployment.yaml
```

### 8. Ingress 설정 (Nginx Ingress Controller)
```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: timingle-ingress
  namespace: timingle-prod
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.timingle.com
    secretName: timingle-tls
  rules:
  - host: api.timingle.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: timingle-api-service
            port:
              number: 80
```

```bash
kubectl apply -f k8s/ingress.yaml
```

### 9. 배포 확인
```bash
# Pod 상태 확인
kubectl get pods

# 서비스 확인
kubectl get svc

# Ingress 확인
kubectl get ingress

# 로그 확인
kubectl logs -f deployment/timingle-api
```

---

## 모니터링 및 로깅

### Prometheus + Grafana

#### Prometheus 설치 (Helm)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

#### Grafana 대시보드
```bash
# Grafana 접속
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# 로그인: admin / prom-operator
# 대시보드: Import → 1860 (Node Exporter Full)
```

### 로깅 (ELK Stack)

#### Elasticsearch + Kibana 설치
```bash
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch --namespace logging --create-namespace
helm install kibana elastic/kibana --namespace logging
```

#### Filebeat 설정
```yaml
# k8s/filebeat-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: logging
data:
  filebeat.yml: |
    filebeat.inputs:
    - type: container
      paths:
        - /var/log/containers/*.log
    output.elasticsearch:
      hosts: ["elasticsearch-master:9200"]
```

---

## 백업 및 복구

### PostgreSQL 백업

#### CronJob 설정
```yaml
# k8s/postgres-backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: timingle-prod
spec:
  schedule: "0 2 * * *"  # 매일 오전 2시
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15-alpine
            command:
            - /bin/sh
            - -c
            - |
              pg_dump -h postgres-service -U timingle -d timingle > /backup/backup-$(date +%Y%m%d-%H%M%S).sql
              # S3에 업로드
              aws s3 cp /backup/backup-$(date +%Y%m%d-%H%M%S).sql s3://timingle-backups/
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
```

### ScyllaDB 스냅샷
```bash
# 수동 스냅샷
kubectl exec -it scylla-0 -- nodetool snapshot timingle

# 스냅샷 복원
kubectl exec -it scylla-0 -- nodetool refresh timingle <table>
```

---

## 롤백 절차

### Kubernetes 롤백
```bash
# 배포 히스토리 확인
kubectl rollout history deployment/timingle-api

# 이전 버전으로 롤백
kubectl rollout undo deployment/timingle-api

# 특정 리비전으로 롤백
kubectl rollout undo deployment/timingle-api --to-revision=2

# 롤백 상태 확인
kubectl rollout status deployment/timingle-api
```

### 데이터베이스 마이그레이션 롤백
```bash
# Backend 컨테이너 접속
kubectl exec -it <api-pod> -- sh

# 마이그레이션 다운
cd /app
migrate -path migrations -database "postgresql://..." down 1
```

---

## CI/CD 파이프라인

### GitHub Actions 예시

**.github/workflows/deploy.yml**:
```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: 1.22

    - name: Build Backend
      run: |
        cd backend
        go build -o bin/api cmd/api/main.go

    - name: Build Docker Image
      run: |
        docker build -t your-registry/timingle-api:${{ github.ref_name }} .
        docker push your-registry/timingle-api:${{ github.ref_name }}

    - name: Deploy to Kubernetes
      uses: azure/k8s-deploy@v1
      with:
        manifests: |
          k8s/api-deployment.yaml
        images: |
          your-registry/timingle-api:${{ github.ref_name }}
        kubectl-version: 'latest'
```

---

## 보안 체크리스트

- [ ] 모든 Secret 암호화
- [ ] TLS/SSL 인증서 설정
- [ ] 방화벽 규칙 설정
- [ ] Rate Limiting 활성화
- [ ] CORS 설정
- [ ] DDoS 방어 (Cloudflare 등)
- [ ] 정기 백업 자동화
- [ ] 모니터링 알림 설정
- [ ] 로그 보관 정책

---

**Version**: 1.0
**최종 업데이트**: 2025-01-01
**참조**: [DEVELOPMENT.md](DEVELOPMENT.md), [ARCHITECTURE.md](ARCHITECTURE.md)
