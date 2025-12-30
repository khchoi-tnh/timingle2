# Phase 5: 배포 및 출시 (Week 4+)

**목표**: 프로덕션 배포, 앱 스토어 출시, 모니터링 설정

**소요 시간**: 3-5일

**완료 조건**:
- ✅ 프로덕션 환경 구성 완료
- ✅ Backend 프로덕션 배포
- ✅ Google Play Store 출시
- ✅ App Store 출시
- ✅ 모니터링 및 로깅 설정
- ✅ CI/CD 파이프라인 구축

---

## 📋 사전 준비사항

### 완료 확인
- [ ] PHASE_1~4 완료
- [ ] 모든 테스트 통과
- [ ] Backend API 안정성 확인
- [ ] Flutter 앱 빌드 성공 (Android + iOS)

### 준비물
- [ ] 도메인 (예: api.timingle.com)
- [ ] SSL 인증서 (Let's Encrypt 또는 구매)
- [ ] Google Play Developer 계정 ($25 일회성)
- [ ] Apple Developer 계정 ($99/년)
- [ ] 클라우드 서버 (AWS, GCP, Azure 등)

---

## 🖥️ Step 1: Backend 프로덕션 배포

### 1.1 환경변수 프로덕션 설정
```bash
# backend/.env.production
PORT=8080
GIN_MODE=release

# PostgreSQL (프로덕션 DB)
POSTGRES_HOST=your-production-db-host
POSTGRES_PORT=5432
POSTGRES_USER=timingle_prod
POSTGRES_PASSWORD=STRONG_PASSWORD_HERE
POSTGRES_DB=timingle_prod

# Redis (프로덕션)
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=REDIS_PASSWORD_HERE

# NATS (프로덕션)
NATS_URL=nats://your-nats-host:4222

# ScyllaDB (프로덕션 클러스터)
SCYLLA_HOSTS=scylla-node1,scylla-node2,scylla-node3
SCYLLA_KEYSPACE=timingle
SCYLLA_CONSISTENCY=QUORUM

# JWT (프로덕션 시크릿 - 256bit 이상)
JWT_SECRET=your-production-jwt-secret-minimum-256-bits
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# External APIs
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
PHONE_VERIFY_API_KEY=your-phone-verify-api-key
```

### 1.2 Docker 이미지 빌드 (Backend)
```bash
cd backend

# Dockerfile 생성
cat > Dockerfile << 'EOF'
# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o api ./cmd/api

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

COPY --from=builder /app/api .
COPY --from=builder /app/.env.production .env

EXPOSE 8080

CMD ["./api"]
EOF

# 이미지 빌드
docker build -t timingle-api:latest .

# Docker Hub에 푸시 (선택)
docker tag timingle-api:latest yourusername/timingle-api:latest
docker push yourusername/timingle-api:latest
```

### 1.3 Kubernetes 배포 (참고: docs/DEPLOYMENT.md)
```bash
# docs/DEPLOYMENT.md 참조
# Kubernetes 매니페스트 적용
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/redis.yaml
kubectl apply -f k8s/nats.yaml
kubectl apply -f k8s/scylla.yaml
kubectl apply -f k8s/api.yaml
kubectl apply -f k8s/ingress.yaml

# 상태 확인
kubectl get pods -n timingle-prod
kubectl get svc -n timingle-prod
kubectl get ingress -n timingle-prod
```

### 1.4 도메인 및 SSL 설정
```bash
# Let's Encrypt 인증서 발급 (Cert-Manager 사용)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# ClusterIssuer 생성
cat > k8s/letsencrypt-issuer.yaml << 'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

kubectl apply -f k8s/letsencrypt-issuer.yaml

# Ingress에 TLS 추가 (k8s/ingress.yaml 수정)
# annotations:
#   cert-manager.io/cluster-issuer: "letsencrypt-prod"
# tls:
# - hosts:
#   - api.timingle.com
#   secretName: timingle-tls
```

---

## 📱 Step 2: Flutter 앱 프로덕션 빌드

### 2.1 환경변수 설정
```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.timingle.com',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
}

// lib/core/di/providers.dart 수정
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(baseUrl: AppConfig.apiBaseUrl, storage: storage);
});
```

### 2.2 Android 프로덕션 빌드

#### android/key.properties 생성 (보안 주의!)
```bash
cd frontend

# 키스토어 생성
keytool -genkey -v -keystore ~/timingle-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias timingle

# key.properties 생성
cat > android/key.properties << 'EOF'
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=timingle
storeFile=/home/yourusername/timingle-release.jks
EOF

# .gitignore에 추가
echo "android/key.properties" >> .gitignore
echo "*.jks" >> .gitignore
```

#### android/app/build.gradle 수정
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...existing code...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### APK 빌드
```bash
# Release APK 빌드
flutter build apk --release --dart-define=API_BASE_URL=https://api.timingle.com

# 또는 App Bundle (Google Play 권장)
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.timingle.com

# 결과물 확인
ls -lh build/app/outputs/bundle/release/app-release.aab
```

### 2.3 iOS 프로덕션 빌드

#### Xcode 설정
```bash
cd frontend/ios

# Podfile 업데이트
pod install

# Xcode에서 열기
open Runner.xcworkspace
```

**Xcode 설정 단계**:
1. Signing & Capabilities
   - Team 선택 (Apple Developer 계정)
   - Bundle Identifier 설정 (예: com.timingle.app)
   - Provisioning Profile 선택

2. Info.plist 수정
   - App Name: `timingle`
   - Version: `1.0.0`
   - Build: `1`

3. 권한 설정 (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>사진을 촬영하거나 업로드하기 위해 카메라 접근이 필요합니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 업로드하기 위해 사진 라이브러리 접근이 필요합니다.</string>
```

#### IPA 빌드
```bash
# iOS Release 빌드
flutter build ios --release --dart-define=API_BASE_URL=https://api.timingle.com

# Archive 생성 (Xcode)
# Product → Archive → Distribute App → App Store Connect
```

---

## 🏪 Step 3: Google Play Store 출시

### 3.1 Google Play Console 설정

1. **계정 생성**
   - https://play.google.com/console
   - Developer 계정 등록 ($25 일회성)

2. **앱 생성**
   - Create app
   - App name: `timingle`
   - Default language: `Korean` (또는 `English`)
   - App category: `Social`

3. **앱 정보 입력**
   - **Short description** (80자):
     ```
     약속이 대화가 되는 앱 - 노쇼 방지, 일정 관리, 실시간 채팅
     ```
   - **Full description** (4000자):
     ```
     timingle은 약속 중심의 커뮤니케이션 플랫폼입니다.

     🎯 핵심 기능:
     - 약속마다 독립적인 채팅방
     - 모든 변경/확정 이력 자동 기록
     - 노쇼 방지 및 책임 추적
     - 실시간 메시징
     - 오픈 예약 시스템 (비즈니스 사용자)

     💡 특징:
     - 약속 없이는 대화 불가 (캐주얼 대화 차단)
     - 일정 변경 시 자동 기록
     - 참여자 확인 강제
     - 다국어 지원 (한국어, 영어)
     ```

4. **스크린샷 업로드**
   - Phone: 최소 2개 (1080x1920 또는 1440x2560)
   - Tablet: 권장 (7인치, 10인치)

5. **앱 카테고리**
   - Category: `Social`
   - Tags: `Meeting`, `Calendar`, `Chat`, `Scheduling`

6. **Contact details**
   - Email: `support@timingle.com`
   - Phone: (선택)
   - Website: `https://timingle.com`

7. **Privacy policy**
   - URL: `https://timingle.com/privacy`

8. **App content**
   - Content rating: `Everyone`
   - Target audience: `18+`

9. **APK/AAB 업로드**
   - Production → Create new release
   - Upload `app-release.aab`
   - Release name: `1.0.0 (Initial Release)`
   - Release notes:
     ```
     Initial release of timingle!
     - Event-based chat system
     - Real-time messaging
     - Event history tracking
     - Multi-language support
     ```

10. **검토 제출**
    - Review → Submit for review
    - 검토 기간: 보통 1~3일

---

## 🍎 Step 4: Apple App Store 출시

### 4.1 App Store Connect 설정

1. **Apple Developer 계정**
   - https://developer.apple.com ($99/년)

2. **App Store Connect**
   - https://appstoreconnect.apple.com
   - My Apps → + → New App

3. **앱 정보 입력**
   - **Platforms**: iOS
   - **Name**: `timingle`
   - **Primary Language**: `Korean` (or `English`)
   - **Bundle ID**: `com.timingle.app`
   - **SKU**: `timingle-001`

4. **앱 정보**
   - **Subtitle** (30자):
     ```
     약속이 대화가 되는 앱
     ```
   - **Description** (4000자): Google Play와 동일
   - **Keywords** (100자):
     ```
     meeting,calendar,chat,schedule,appointment,timingle
     ```
   - **Support URL**: `https://timingle.com/support`
   - **Marketing URL**: `https://timingle.com`

5. **스크린샷**
   - 6.5" Display (iPhone 14 Pro Max): 1284x2778
   - 5.5" Display (iPhone 8 Plus): 1242x2208
   - 최소 1개씩 필요

6. **앱 리뷰 정보**
   - **Demo account** (테스트용):
     - Username: `demo@timingle.com`
     - Password: `TestPassword123!`
   - **Notes**:
     ```
     테스트를 위해 demo 계정을 사용해주세요.
     전화번호 인증 시 코드는 "123456"을 입력하면 됩니다.
     ```

7. **Version Information**
   - Version: `1.0.0`
   - Copyright: `2025 timingle`

8. **Build 업로드**
   - Xcode → Product → Archive
   - Organizer → Distribute App → App Store Connect
   - Upload → Automatic signing
   - 업로드 완료 후 TestFlight에서 확인

9. **TestFlight 테스트**
   - Internal Testing: 개발팀
   - External Testing: 베타 테스터 (선택)

10. **검토 제출**
    - App Store → Submit for Review
    - 검토 기간: 보통 1~3일

---

## 📊 Step 5: 모니터링 및 로깅

### 5.1 Backend 모니터링 (Prometheus + Grafana)
```bash
# docs/DEPLOYMENT.md 참조
# Prometheus 및 Grafana 설치 완료 가정

# Grafana 대시보드 접속
# http://your-server-ip:3000

# 주요 메트릭:
# - API 요청 수 (QPS)
# - 응답 시간 (P50, P95, P99)
# - 에러율 (4xx, 5xx)
# - WebSocket 연결 수
# - ScyllaDB 읽기/쓰기 지연시간
# - NATS 메시지 처리량
```

### 5.2 Frontend 모니터링 (Firebase Crashlytics)
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_crashlytics: ^3.4.9
  firebase_analytics: ^10.7.4
```

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp();

  // Crashlytics 설정
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Analytics 설정
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  runApp(MyApp(analytics: analytics));
}
```

### 5.3 로그 수집 (ELK Stack)
```bash
# docs/DEPLOYMENT.md 참조
# Elasticsearch + Logstash + Kibana 설치

# Kibana 대시보드 접속
# http://your-server-ip:5601

# 주요 로그:
# - API 요청 로그
# - 에러 로그 (500, panic)
# - WebSocket 연결/해제 로그
# - ScyllaDB 쿼리 로그
```

---

## 🔄 Step 6: CI/CD 파이프라인

### 6.1 GitHub Actions (Backend)
```yaml
# .github/workflows/backend-ci.yml
name: Backend CI/CD

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'
  pull_request:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.22'

      - name: Run tests
        working-directory: ./backend
        run: |
          go test -v ./...

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        working-directory: ./backend
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/timingle-api:${{ github.sha }} .
          docker tag ${{ secrets.DOCKER_USERNAME }}/timingle-api:${{ github.sha }} ${{ secrets.DOCKER_USERNAME }}/timingle-api:latest

      - name: Push to Docker Hub
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          docker push ${{ secrets.DOCKER_USERNAME }}/timingle-api:${{ github.sha }}
          docker push ${{ secrets.DOCKER_USERNAME }}/timingle-api:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Kubernetes
        run: |
          # kubectl set image deployment/api api=${{ secrets.DOCKER_USERNAME }}/timingle-api:${{ github.sha }} -n timingle-prod
          echo "Deployment completed"
```

### 6.2 GitHub Actions (Frontend)
```yaml
# .github/workflows/frontend-ci.yml
name: Frontend CI/CD

on:
  push:
    branches: [main]
    paths:
      - 'frontend/**'
  pull_request:
    branches: [main]
    paths:
      - 'frontend/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Install dependencies
        working-directory: ./frontend
        run: flutter pub get

      - name: Run tests
        working-directory: ./frontend
        run: flutter test

      - name: Analyze code
        working-directory: ./frontend
        run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Build APK
        working-directory: ./frontend
        run: |
          flutter build apk --release --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: frontend/build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Build iOS
        working-directory: ./frontend
        run: |
          flutter build ios --release --no-codesign --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}
```

---

## ✅ 완료 체크리스트

### Phase 5 완료 조건
- [ ] Backend 프로덕션 배포 완료 (Kubernetes 또는 VM)
- [ ] HTTPS 설정 완료 (SSL 인증서)
- [ ] 도메인 연결 (api.timingle.com)
- [ ] Flutter Android APK/AAB 빌드 성공
- [ ] Flutter iOS IPA 빌드 성공
- [ ] Google Play Store 제출 완료
- [ ] Apple App Store 제출 완료
- [ ] Firebase Crashlytics 연동
- [ ] Prometheus + Grafana 모니터링 설정
- [ ] ELK Stack 로그 수집 설정
- [ ] CI/CD 파이프라인 동작 확인
- [ ] 프로덕션 환경 smoke test 통과

### 출시 후 모니터링
```bash
# API 서버 상태 확인
curl https://api.timingle.com/health

# Kubernetes Pod 상태
kubectl get pods -n timingle-prod

# 로그 확인
kubectl logs -f deployment/api -n timingle-prod

# Grafana 대시보드
# http://monitoring.timingle.com:3000

# Kibana 로그
# http://logs.timingle.com:5601
```

---

## 🎯 출시 후 단계

### Week 5-8: 초기 사용자 피드백
- [ ] 첫 50명 사용자 확보
- [ ] 피드백 수집 (앱 스토어 리뷰, 설문조사)
- [ ] 주요 버그 수정
- [ ] 성능 개선

### Month 2-3: 기능 확장
- [ ] Open Timingle (오픈 예약) 고도화
- [ ] 결제 연동 (Toss Payments, Stripe)
- [ ] 광고 시스템 구축
- [ ] Pro 플랜 출시

### Month 4-6: 글로벌 확장
- [ ] 일본어, 중국어 지원
- [ ] 지역별 마케팅
- [ ] B2B 기능 추가

---

## 📊 성공 지표 (KPI)

### 주요 메트릭
- **DAU/MAU**: 일일/월간 활성 사용자
- **Retention Rate**: 7일, 30일 재방문율
- **Churn Rate**: 이탈률
- **Event Creation Rate**: 사용자당 이벤트 생성 수
- **Message Count**: 일일 메시지 전송 수
- **No-Show Reduction**: 노쇼율 감소 (목표: 30% 감소)

### 비즈니스 메트릭
- **Conversion Rate**: 무료 → Pro 전환율
- **ARPU**: 사용자당 평균 수익
- **Open Slot Booking Rate**: 오픈 예약 전환율

---

## 🎉 축하합니다!

**timingle MVP 출시 완료!** 🚀

이제 다음 단계로:
1. 사용자 피드백 수집
2. 지속적인 개선
3. 기능 확장
4. 글로벌 시장 진출

**성공을 기원합니다!** 🎊
