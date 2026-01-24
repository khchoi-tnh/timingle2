# Mermaid 다이어그램

이 폴더에는 프로젝트의 주요 흐름을 시각화한 Mermaid 다이어그램이 포함되어 있습니다.

## 📁 파일 목록

| 파일 | 설명 |
|-----|------|
| [auth_google_oauth.md](auth_google_oauth.md) | Google OAuth 인증 흐름 |
| [auth_google_calendar.md](auth_google_calendar.md) | Google Calendar 권한 포함 로그인 |
| [auth_oauth_playground.md](auth_oauth_playground.md) | OAuth Playground로 토큰 발급 |
| [flutter_clean_architecture.md](flutter_clean_architecture.md) | Flutter Clean Architecture 레이어 흐름 |
| [friend_invite_system.md](friend_invite_system.md) | 친구/초대 시스템 흐름 |

## 🔧 사용 방법

### VSCode에서 보기
1. Mermaid Preview 확장 설치
2. `.md` 파일 열기
3. `Ctrl+Shift+V`로 미리보기

### GitHub에서 보기
GitHub은 Mermaid를 기본 지원하므로 파일을 열면 자동으로 렌더링됩니다.

### 온라인 에디터
- https://mermaid.live

## 📝 다이어그램 작성 규칙

```markdown
## 제목

설명 텍스트

` ` `mermaid
sequenceDiagram
    participant A as 참여자A
    participant B as 참여자B
    A->>B: 메시지
` ` `
```

## 🎨 참여자 아이콘

| 아이콘 | 의미 |
|-------|------|
| 📱 | Flutter 앱 |
| 🖥️ | Backend API |
| 🔵 | Google 서비스 |
| 🗄️ | Database |
| 📅 | Calendar API |
| 👤 | 사용자/개발자 |
