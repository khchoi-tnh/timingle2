# timingle 브랜드 가이드라인

## 📋 목차

1. [브랜드 철학](#브랜드-철학)
2. [로고](#로고)
3. [색상 팔레트](#색상-팔레트)
4. [타이포그래피](#타이포그래피)
5. [UI 컴포넌트](#ui-컴포넌트)
6. [아이콘](#아이콘)
7. [사용 예시](#사용-예시)

---

## 브랜드 철학

### timingle (Time + Mingle)
> "약속이 대화가 되는 앱"

### 핵심 가치
- **Simple**: 복잡하지 않은 간결한 UI
- **Reliable**: 신뢰할 수 있는 약속 관리
- **Transparent**: 모든 변경 이력 공개
- **Responsible**: 책임 있는 약속 문화

### 브랜드 톤앤매너
- **친근하지만 전문적**: 비즈니스에서도 사용 가능
- **깔끔하고 모던**: 심플한 디자인
- **밝고 긍정적**: 하늘색 계열 사용

---

## 로고

### 최종 로고: IMG_6707.jpg 스타일

#### 디자인 컨셉
- **형태**: 알람시계 + 말풍선 결합 (3D 스타일)
- **스타일**: 플랫하고 모던한 느낌
- **의미**:
  - 알람시계: 시간 약속
  - 말풍선: 대화/커뮤니케이션
  - 결합: "약속이 대화가 되는" 핵심 철학

#### 색상 구성
- **배경**: 블루 그라디언트
  - 상단: `#2E4A8F` (진한 네이비 블루)
  - 하단: `#5EC4E8` (밝은 하늘색)
- **아이콘**:
  - 시계 테두리: `#1E3A6F` (진한 네이비)
  - 시계 바늘: `#1E3A6F`
  - 시계 몸체: 흰색 (`#FFFFFF`)
  - 벨: 은색/회색 (`#C0C0C0`)

### 로고 변형

#### 1. 앱 아이콘 (512x512)
```
용도: iOS/Android 앱 아이콘
파일명: app_icon_512.png, app_icon_1024.png
형태: 둥근 모서리 정사각형
배경: 블루 그라디언트
내용: 알람시계 + 말풍선 (중앙 배치)
```

#### 2. 로고 + 워드마크 (가로형)
```
용도: 스플래시 화면, 마케팅 자료
파일명: logo_horizontal.svg, logo_horizontal.png
배경: 투명 또는 흰색
구성: [로고 아이콘] timingle (로고 오른쪽에 텍스트)
```

#### 3. 로고 + 워드마크 (세로형)
```
용도: 인쇄물, 포스터
파일명: logo_vertical.svg, logo_vertical.png
배경: 투명 또는 흰색
구성: [로고 아이콘]
       timingle
       (로고 아래 텍스트)
```

#### 4. 파비콘 (32x32)
```
용도: 웹사이트 파비콘
파일명: favicon.ico, favicon.png
형태: 정사각형
내용: 알람시계만 (간소화)
```

#### 5. 다크 모드 변형
```
배경: 어두운 그라디언트
  - 상단: #1A2745 (매우 진한 네이비)
  - 하단: #2C5F7F (진한 블루)
아이콘: 밝은 색상 강조
```

### 최소 크기 및 여백

#### 최소 크기
- **디지털**: 32x32px 이상
- **인쇄**: 15mm x 15mm 이상

#### 여백 (Clear Space)
- 로고 주변 최소 여백: 로고 높이의 1/4

```
┌─────────────────────────┐
│                         │
│    ┌─────────────┐     │
│    │             │     │
│    │    LOGO     │     │ ← 여백: 로고 높이의 1/4
│    │             │     │
│    └─────────────┘     │
│                         │
└─────────────────────────┘
```

### 로고 사용 금지 사항
❌ 로고 비율 변경 (늘리거나 압축)
❌ 로고 회전
❌ 로고 색상 임의 변경
❌ 로고에 그림자/효과 추가 (공식 버전 외)
❌ 로고와 배경 대비 부족 (가독성 저하)

---

## 색상 팔레트

### Primary Colors (주 색상)

#### Primary Blue
```
HEX: #2E4A8F
RGB: 46, 74, 143
CMYK: 68, 48, 0, 44
사용처: 메인 브랜드 컬러, 헤더, 버튼
```

#### Secondary Blue
```
HEX: #5EC4E8
RGB: 94, 196, 232
CMYK: 59, 16, 0, 9
사용처: 보조 컬러, 그라디언트, 강조
```

### Accent Colors (강조 색상)

#### Accent Blue (포인트 버튼)
```
HEX: #3B82F6
RGB: 59, 130, 246
사용처: CTA 버튼, 링크, 활성 상태
```

#### Purple (추천, 특별)
```
HEX: #8B5CF6
RGB: 139, 92, 246
사용처: Pro 기능, 추천 배지
```

#### Warning Yellow (미확정)
```
HEX: #FBBF24
RGB: 251, 191, 36
사용처: 미확정 상태, 경고
```

#### Success Green (확정)
```
HEX: #10B981
RGB: 16, 185, 129
사용처: 확정 상태, 성공 메시지
```

#### Error Red (취소, 오류)
```
HEX: #EF4444
RGB: 239, 68, 68
사용처: 취소 상태, 오류 메시지
```

### Neutral Colors (중립 색상)

#### Gray Scale
```
White:       #FFFFFF (배경)
Gray 50:     #F9FAFB (라이트 배경)
Gray 100:    #F3F4F6 (카드 배경)
Gray 200:    #E5E7EB (구분선)
Gray 300:    #D1D5DB (비활성 테두리)
Gray 400:    #9CA3AF (비활성 텍스트)
Gray 500:    #6B7280 (부가 텍스트)
Gray 600:    #4B5563 (일반 텍스트)
Gray 700:    #374151 (진한 텍스트)
Gray 800:    #1F2937 (헤더 텍스트)
Gray 900:    #111827 (최대 강조 텍스트)
Black:       #000000 (사용 최소화)
```

### 그라디언트

#### Brand Gradient (브랜드 그라디언트)
```
linear-gradient(135deg, #2E4A8F 0%, #5EC4E8 100%)
사용처: 로고 배경, 히어로 섹션
```

#### Soft Blue Gradient
```
linear-gradient(135deg, #3B82F6 0%, #8B5CF6 100%)
사용처: 카드 강조, 프리미엄 기능
```

### 색상 사용 가이드

#### 텍스트
- **헤더**: Gray 800 또는 Gray 900
- **본문**: Gray 700
- **부가 정보**: Gray 500
- **비활성**: Gray 400
- **링크**: Accent Blue (#3B82F6)

#### 배경
- **앱 배경**: White 또는 Gray 50
- **카드**: White (그림자 포함)
- **섹션 구분**: Gray 100

#### 상태 표시
| 상태 | 색상 | HEX |
|------|------|-----|
| 제안됨 (PROPOSED) | Warning Yellow | #FBBF24 |
| 확정됨 (CONFIRMED) | Success Green | #10B981 |
| 완료됨 (DONE) | Gray 500 | #6B7280 |
| 취소됨 (CANCELED) | Error Red | #EF4444 |

---

## 타이포그래피

### 폰트 패밀리

#### 한글
```
Primary: Pretendard (추천)
Fallback: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Malgun Gothic", sans-serif
```

#### 영문/숫자
```
Primary: Inter
Fallback: Helvetica, Arial, sans-serif
```

#### 코드 (선택)
```
Monospace: JetBrains Mono, "Courier New", monospace
```

### 타입 스케일

#### 디스플레이 (큰 제목)
```
크기: 36px (2.25rem)
무게: 700 (Bold)
행간: 1.2
사용처: 히어로 섹션 제목
```

#### H1 (주 제목)
```
크기: 30px (1.875rem)
무게: 700 (Bold)
행간: 1.3
사용처: 페이지 제목
```

#### H2 (부 제목)
```
크기: 24px (1.5rem)
무게: 600 (SemiBold)
행간: 1.4
사용처: 섹션 제목
```

#### H3 (소 제목)
```
크기: 20px (1.25rem)
무게: 600 (SemiBold)
행간: 1.4
사용처: 카드 제목
```

#### Body Large
```
크기: 18px (1.125rem)
무게: 400 (Regular)
행간: 1.6
사용처: 강조 본문
```

#### Body (본문)
```
크기: 16px (1rem)
무게: 400 (Regular)
행간: 1.6
사용처: 일반 본문
```

#### Body Small
```
크기: 14px (0.875rem)
무게: 400 (Regular)
행간: 1.5
사용처: 부가 정보, 캡션
```

#### Caption
```
크기: 12px (0.75rem)
무게: 400 (Regular)
행간: 1.4
사용처: 메타 정보, 타임스탬프
```

#### Button
```
크기: 16px (1rem)
무게: 600 (SemiBold)
행간: 1.2
사용처: 버튼 텍스트
```

#### Badge
```
크기: 12px (0.75rem)
무게: 600 (SemiBold)
행간: 1.2
사용처: 상태 배지
```

---

## UI 컴포넌트

### 버튼

#### Primary Button
```
배경: Accent Blue (#3B82F6)
텍스트: White (#FFFFFF)
패딩: 12px 24px
둥근 모서리: 8px
그림자: 0 2px 8px rgba(59, 130, 246, 0.3)
Hover: 배경 10% 어둡게
```

#### Secondary Button
```
배경: 투명
테두리: 2px solid Primary Blue (#2E4A8F)
텍스트: Primary Blue (#2E4A8F)
패딩: 12px 24px
둥근 모서리: 8px
Hover: 배경 Gray 50
```

#### Ghost Button
```
배경: 투명
텍스트: Gray 700
패딩: 8px 16px
Hover: 배경 Gray 100
```

### 카드

#### Event Card (이벤트 카드)
```
배경: White
테두리: 1px solid Gray 200
둥근 모서리: 12px
그림자: 0 1px 3px rgba(0, 0, 0, 0.1)
패딩: 16px
Hover: 그림자 0 4px 12px rgba(0, 0, 0, 0.15)
```

### 입력 필드

#### Text Input
```
배경: White
테두리: 1px solid Gray 300
둥근 모서리: 8px
패딩: 12px 16px
Focus: 테두리 Accent Blue, 그림자 0 0 0 3px rgba(59, 130, 246, 0.2)
```

### 배지

#### Status Badge
```
패딩: 4px 12px
둥근 모서리: 12px (pill 모양)
폰트: Badge (12px SemiBold)
배경/텍스트: 상태에 따라 변경
```

예시:
- PROPOSED: 배경 #FEF3C7, 텍스트 #92400E
- CONFIRMED: 배경 #D1FAE5, 텍스트 #065F46
- DONE: 배경 #F3F4F6, 텍스트 #374151
- CANCELED: 배경 #FEE2E2, 텍스트 #991B1B

---

## 아이콘

### 아이콘 스타일
- **스타일**: Outline (기본), Solid (강조)
- **두께**: 2px stroke
- **크기**: 20px, 24px, 32px (3 사이즈)
- **색상**: Gray 600 (기본), Primary Blue (활성)

### 주요 아이콘

```
홈 (House): Timingle 메인
캘린더 (Calendar): Timeline
오픈 (Calendar Plus): Open Timingle
친구 (Users): 친구 목록
설정 (Gear): 설정

시계 (Clock): 시간
위치 (Map Pin): 장소
사람 (User): 프로필
메시지 (Chat Bubble): 채팅
알림 (Bell): 알림
확인 (Check): 확정
취소 (X): 취소
편집 (Pencil): 수정
검색 (Magnifying Glass): 검색
```

### 아이콘 라이브러리
- **추천**: [Heroicons](https://heroicons.com/) (무료, MIT 라이선스)
- **대안**: [Feather Icons](https://feathericons.com/)

---

## 사용 예시

### 1. 이벤트 카드 (Timingle 메인)
```
┌────────────────────────────────────┐
│ 👤 [프로필 이미지]  9am -> 길동이   │
│                                    │
│ 📍 강남 피트니스                    │
│ 🕐 1월 5일 (목) 오전 9:00          │
│                                    │
│ [확정됨] ✅ 3                       │ ← Success Green 배지
└────────────────────────────────────┘
```

### 2. 채팅 메시지
```
발신자 메시지 (왼쪽):
┌────────────────────────┐
│ 안녕하세요!             │
│                        │
│ 10:30 AM               │
└────────────────────────┘
배경: Gray 100
텍스트: Gray 900

내 메시지 (오른쪽):
             ┌────────────────────────┐
             │ 네, 반갑습니다!         │
             │                        │
             │               10:32 AM │
             └────────────────────────┘
배경: Accent Blue (#3B82F6)
텍스트: White
```

### 3. 하단 네비게이션
```
┌──────┬──────┬──────┬──────┬──────┐
│ 🏠   │ 📅   │  +   │ 👥   │ ⚙️   │
│ Home │ Time │ Open │Friend│Setting│
└──────┴──────┴──────┴──────┴──────┘

활성: Primary Blue (#2E4A8F)
비활성: Gray 400 (#9CA3AF)
```

---

## 다운로드 및 리소스

### 로고 파일
```
assets/logo/
├── app_icon_512.png
├── app_icon_1024.png
├── logo_horizontal.svg
├── logo_horizontal.png
├── logo_vertical.svg
├── logo_vertical.png
├── favicon.ico
└── favicon.png
```

### 색상 파일
```
assets/colors/
├── timingle_colors.ase (Adobe Swatch)
├── timingle_colors.json
└── timingle_colors.md
```

### 폰트
- [Pretendard](https://github.com/orioncactus/pretendard) - 무료, OFL
- [Inter](https://rsms.me/inter/) - 무료, OFL

---

## 브랜드 사용 승인

timingle 브랜드 자산(로고, 색상, 이름)을 사용하려면 사전 승인이 필요합니다.

문의: [브랜드 팀 이메일]

---

**Version**: 1.0
**최종 업데이트**: 2025-01-01
**담당자**: Brand Team
