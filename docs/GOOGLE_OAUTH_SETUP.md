# Google OAuth 설정 가이드

timingle 앱에서 Google 로그인을 사용하기 위한 설정 가이드입니다.

## 1. Google Cloud Console 프로젝트 설정

### 1.1 프로젝트 생성
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 상단 프로젝트 선택 → **새 프로젝트**
3. 프로젝트 이름: `timingle` (또는 원하는 이름)
4. **만들기** 클릭

### 1.2 OAuth 동의 화면 설정
1. **APIs & Services** → **OAuth consent screen**
2. User Type: **External** 선택 → **만들기**
3. 앱 정보 입력:
   - 앱 이름: `timingle`
   - 사용자 지원 이메일: 본인 이메일
   - 개발자 연락처 이메일: 본인 이메일
4. **저장 후 계속**
5. Scopes: 기본값 유지 → **저장 후 계속**
6. Test users: 테스트할 Google 계정 추가 → **저장 후 계속**

## 2. OAuth 2.0 클라이언트 ID 생성

**APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**

### 2.1 Android 클라이언트

| 항목 | 값 |
|------|-----|
| Application type | Android |
| Name | `timingle-android` |
| Package name | `com.timingle.app` |
| SHA-1 certificate fingerprint | [아래 참조](#sha-1-지문-확인-방법) |

### 2.2 iOS 클라이언트

| 항목 | 값 |
|------|-----|
| Application type | iOS |
| Name | `timingle-ios` |
| Bundle ID | `com.timingle.app` |

### 2.3 Web 클라이언트

| 항목 | 값 |
|------|-----|
| Application type | Web application |
| Name | `timingle-web` |
| Authorized JavaScript origins | `https://timingle.com`<br>`https://www.timingle.com`<br>`http://localhost:8080` (개발용) |
| Authorized redirect URIs | `https://timingle.com/auth/google/callback`<br>`https://www.timingle.com/auth/google/callback`<br>`http://localhost:8080/auth/google/callback` (개발용)<br>`https://developers.google.com/oauthplayground` **(테스트용 필수)** |

> **참고**: Web 클라이언트는 ID 토큰 검증에 사용됩니다.
>
> **중요**: OAuth Playground로 테스트하려면 redirect URI에 `https://developers.google.com/oauthplayground`를 반드시 추가해야 합니다.

## 3. SHA-1 지문 확인 방법

### Debug 키 (개발용)

**Windows CMD:**
```cmd
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Windows PowerShell:**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**macOS/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

출력에서 `SHA1:` 값을 복사합니다:
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

### Release 키 (배포용)
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-alias
```

## 4. 환경변수 설정

### Backend (.env)
```bash
# Google OAuth
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com        # Android Client ID
GOOGLE_CLIENT_ID_IOS=xxx.apps.googleusercontent.com    # iOS Client ID
GOOGLE_CLIENT_ID_WEB=xxx.apps.googleusercontent.com    # Web Client ID (토큰 검증용)
```

### run.sh 업데이트
```bash
export GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
export GOOGLE_CLIENT_ID_IOS=xxx.apps.googleusercontent.com
export GOOGLE_CLIENT_ID_WEB=xxx.apps.googleusercontent.com
```

## 5. Flutter 설정

### 5.1 google_sign_in 패키지 추가
```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^6.2.1
```

### 5.2 Android 설정

`android/app/build.gradle.kts`에 이미 설정됨:
```kotlin
defaultConfig {
    applicationId = "com.timingle.app"
    // ...
}
```

### 5.3 iOS 설정

`ios/Runner/Info.plist`에 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed client ID -->
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
        </array>
    </dict>
</array>
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
```

## 6. 테스트

### 6.1 Postman 테스트 (권장)

#### Step 1: Postman Collection 가져오기
```
File > Import > docs/timingle-api.postman_collection.json
```

#### Step 2: Google ID Token 획득

1. **[Google OAuth Playground](https://developers.google.com/oauthplayground)** 접속
2. 우측 상단 **톱니바퀴(⚙️)** 클릭
3. **"Use your own OAuth credentials"** 체크
4. 다음 정보 입력:
   - **OAuth Client ID**: `412931718610-688tjrfrajl25al760ro6gaica95jft6.apps.googleusercontent.com` (Web)
   - **OAuth Client Secret**: Google Cloud Console에서 확인
5. 좌측에서 Scope 선택 (Step 1):
   - `openid`
   - `https://www.googleapis.com/auth/userinfo.email`
   - `https://www.googleapis.com/auth/userinfo.profile`
6. **"Authorize APIs"** 클릭 → Google 계정 로그인
7. **"Exchange authorization code for tokens"** 클릭 (Step 2)
8. 응답에서 **`id_token`** 값 복사

#### Step 3: Postman에서 요청

**Auth > Google Login** 선택:
```json
{
  "id_token": "<복사한_ID_TOKEN>",
  "platform": "web"
}
```

> **platform 값**: `web` | `android` | `ios`

### 6.2 curl 테스트

```bash
# Google 로그인 API (ID 토큰 필요)
curl -X POST http://localhost:8080/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "eyJhbGciOiJSUzI1NiIs...",
    "platform": "web"
  }'
```

### 6.3 Flutter 앱 테스트

#### Android Emulator
1. WSL에서 서버 실행:
   ```bash
   cd ~/projects/timingle2/containers
   podman-compose -f podman-compose-wsl.yml up -d
   cd ~/projects/timingle2/backend
   ./run.sh
   ```
2. Android Emulator 실행
3. Flutter 앱 실행:
   ```bash
   cd D:\projects\timingle2\frontend
   flutter run
   ```
4. Google 로그인 버튼 클릭

> **참고**: Android Emulator는 `10.0.2.2`로 호스트 머신 접근 (자동 설정됨)

### 6.4 응답 예시
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid-string",
    "email": "user@gmail.com",
    "name": "User Name",
    "profile_image": "https://..."
  }
}
```

## 7. 프로덕션 체크리스트

- [ ] OAuth 동의 화면에서 앱 검토 요청 (프로덕션 전환)
- [ ] Release SHA-1 지문 추가
- [ ] 프로덕션 도메인 Authorized origins에 추가
- [ ] 환경변수를 프로덕션 값으로 변경
- [ ] HTTPS 적용

## 8. 문제 해결

### "Invalid client ID" 오류
- Client ID가 올바른지 확인
- 플랫폼별 올바른 Client ID 사용 확인

### "SHA-1 mismatch" 오류
- Debug/Release 키 구분 확인
- Google Console에 등록된 SHA-1과 일치하는지 확인

### "Access blocked" 오류
- OAuth 동의 화면에서 테스트 사용자로 등록되었는지 확인
- 앱이 테스트 모드인 경우 등록된 사용자만 로그인 가능

## 참고 링크

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google Cloud Console](https://console.cloud.google.com/)
- [OAuth 2.0 개요](https://developers.google.com/identity/protocols/oauth2)
