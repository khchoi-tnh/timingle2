# timingle UI 화면 명세서

## 📋 목차

1. [화면 구조 개요](#화면-구조-개요)
2. [0. 로그인 화면](#0-로그인-화면)
3. [1. Timingle (Home)](#1-timingle-home)
4. [2. Timeline](#2-timeline)
5. [3. Open Timingle](#3-open-timingle)
6. [4. Friends](#4-friends)
7. [5. Settings](#5-settings)
8. [6. 이벤트 상세/채팅](#6-이벤트-상세채팅)
9. [공통 컴포넌트](#공통-컴포넌트)

---

## 화면 구조 개요

### 네비게이션 구조
```
LoginPage (초기)
    ↓ (인증 성공)
MainPage (하단 네비게이션)
    ├─ 1. Timingle (Home)
    ├─ 2. Timeline
    ├─ 3. Open Timingle
    ├─ 4. Friends
    └─ 5. Settings

EventDetailPage (모달/푸시)
    └─ 이벤트 상세 + 채팅
```

### 하단 네비게이션 바
```
┌──────────────────────────────────────────────┐
│  🏠        📅         +          👥        ⚙️  │
│ Home    Timeline    Open     Friends   Settings│
└──────────────────────────────────────────────┘
```

- **활성 색상**: Primary Blue (#2E4A8F)
- **비활성 색상**: Gray 400 (#9CA3AF)
- **배경**: White, 상단 경계선 (Gray 200)

---

## 0. 로그인 화면

### 파일 경로
```
lib/features/auth/presentation/pages/login_page.dart
```

### 레이아웃
```
┌────────────────────────────────┐
│                                │
│          (여백)                │
│                                │
│      [timingle 로고]           │ ← 중앙 배치
│                                │
│   약속이 대화가 되는 앱         │ ← Subtitle
│                                │
│                                │
│  ┌──────────────────────────┐ │
│  │  🔵 Continue with Google │ │ ← Primary Button
│  └──────────────────────────┘ │
│                                │
│  ┌──────────────────────────┐ │
│  │  📱 전화번호로 로그인      │ │ ← Secondary Button
│  └──────────────────────────┘ │
│                                │
│          (여백)                │
│                                │
└────────────────────────────────┘
```

### UI 요소

#### 로고
- **크기**: 120x120px
- **위치**: 화면 중앙 상단 (화면 높이의 30% 지점)
- **스타일**: IMG_6707.jpg 스타일 (알람시계 + 말풍선)

#### 타이틀
```dart
Text(
  'timingle',
  style: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2E4A8F), // Primary Blue
  ),
)
```

#### 서브타이틀
```dart
Text(
  '약속이 대화가 되는 앱',
  style: TextStyle(
    fontSize: 16,
    color: Color(0xFF6B7280), // Gray 500
  ),
)
```

#### Google 로그인 버튼
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF3B82F6), // Accent Blue
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.g_mobiledata), // Google 아이콘
      SizedBox(width: 8),
      Text('Continue with Google'),
    ],
  ),
  onPressed: () => _handleGoogleLogin(),
)
```

#### 전화번호 로그인 버튼
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Color(0xFF2E4A8F), // Primary Blue
    side: BorderSide(color: Color(0xFF2E4A8F), width: 2),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.phone),
      SizedBox(width: 8),
      Text('전화번호로 로그인'),
    ],
  ),
  onPressed: () => _handlePhoneLogin(),
)
```

---

## 1. Timingle (Home)

### 파일 경로
```
lib/features/timingle/presentation/pages/timingle_page.dart
lib/features/timingle/presentation/widgets/event_card.dart
```

### 레이아웃
```
┌────────────────────────────────────┐
│ Timingle              🔍  [프로필] │ ← 상단 앱바
├────────────────────────────────────┤
│ 📅 전체  |  예정  |  완료          │ ← 필터 탭
├────────────────────────────────────┤
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 👤 [프로필]  9am -> 길동이      │ │ ← 이벤트 카드
│ │                                │ │
│ │ 📍 강남 피트니스                │ │
│ │ 🕐 1월 5일 (목) 오전 9:00      │ │
│ │                                │ │
│ │ [확정됨] ✅ 3                   │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 👤 [프로필]  3pm -> Jake       │ │
│ │                                │ │
│ │ 📍 홍대 카페                    │ │
│ │ 🕐 1월 6일 (금) 오후 3:00      │ │
│ │                                │ │
│ │ [제안됨] ⏰ 2                   │ │
│ └────────────────────────────────┘ │
│                                    │
│          (스크롤 가능)              │
│                                    │
├────────────────────────────────────┤
│     [하단 네비게이션 바]            │
└────────────────────────────────────┘
```

### UI 요소

#### 상단 앱바
```dart
AppBar(
  title: Text('Timingle'),
  backgroundColor: Colors.white,
  foregroundColor: Color(0xFF1F2937), // Gray 800
  elevation: 0,
  actions: [
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () => _openSearch(),
    ),
    CircleAvatar(
      backgroundImage: NetworkImage(user.profileImageUrl),
    ),
    SizedBox(width: 16),
  ],
)
```

#### 필터 탭
```dart
TabBar(
  tabs: [
    Tab(text: '전체'),
    Tab(text: '예정'),
    Tab(text: '완료'),
  ],
  labelColor: Color(0xFF2E4A8F), // Primary Blue
  unselectedLabelColor: Color(0xFF9CA3AF), // Gray 400
  indicatorColor: Color(0xFF2E4A8F),
)
```

#### 이벤트 카드
```dart
Card(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: InkWell(
    onTap: () => _openEventDetail(event.id),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 프로필 + 제목
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(event.creator.profileImageUrl),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title, // "9am -> 길동이"
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // 위치
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(event.location),
            ],
          ),
          SizedBox(height: 4),

          // 시간
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(_formatDateTime(event.startTime)),
            ],
          ),
          SizedBox(height: 12),

          // 하단: 상태 배지 + 참여자 수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(event.status),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16),
                  SizedBox(width: 4),
                  Text('${event.confirmedCount}'),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  ),
)
```

#### 상태 배지
```dart
Widget _buildStatusBadge(EventStatus status) {
  Color bgColor, textColor;
  String text;

  switch (status) {
    case EventStatus.PROPOSED:
      bgColor = Color(0xFFFEF3C7); // Warning Yellow Light
      textColor = Color(0xFF92400E); // Warning Yellow Dark
      text = '제안됨';
      break;
    case EventStatus.CONFIRMED:
      bgColor = Color(0xFFD1FAE5); // Success Green Light
      textColor = Color(0xFF065F46); // Success Green Dark
      text = '확정됨';
      break;
    case EventStatus.DONE:
      bgColor = Color(0xFFF3F4F6); // Gray 100
      textColor = Color(0xFF374151); // Gray 700
      text = '완료됨';
      break;
    case EventStatus.CANCELED:
      bgColor = Color(0xFFFEE2E2); // Error Red Light
      textColor = Color(0xFF991B1B); // Error Red Dark
      text = '취소됨';
      break;
  }

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
  );
}
```

#### 플로팅 액션 버튼
```dart
FloatingActionButton(
  onPressed: () => _createNewEvent(),
  backgroundColor: Color(0xFF3B82F6), // Accent Blue
  child: Icon(Icons.add, color: Colors.white),
)
```

---

## 2. Timeline

### 파일 경로
```
lib/features/timeline/presentation/pages/timeline_page.dart
lib/features/timeline/presentation/widgets/timeline_event_tile.dart
```

### 레이아웃
```
┌────────────────────────────────────┐
│ Timeline          📅 [날짜 선택]   │ ← 상단 앱바
├────────────────────────────────────┤
│ < 1월 5일 (목) >                   │ ← 날짜 네비게이션
├────────────────────────────────────┤
│                                    │
│ 06:00 ────────────────────────     │
│ 07:00 ────────────────────────     │
│ 08:00 ────────────────────────     │
│ 09:00 ┌─────────────────────┐     │
│       │ 9am -> 길동이        │     │ ← 이벤트 블록
│       │ 강남 피트니스         │     │
│ 10:00 └─────────────────────┘     │
│ 11:00 ────────────────────────     │
│ 12:00 ────────────────────────     │
│       ...                          │
│ 15:00 ┌─────────────────────┐     │
│       │ 3pm -> Jake          │     │
│ 16:00 │ 홍대 카페             │     │
│       └─────────────────────┘     │
│                                    │
│          (스크롤 가능)              │
│                                    │
├────────────────────────────────────┤
│     [하단 네비게이션 바]            │
└────────────────────────────────────┘
```

### UI 요소

#### 상단 앱바
```dart
AppBar(
  title: Text('Timeline'),
  actions: [
    IconButton(
      icon: Icon(Icons.calendar_today),
      onPressed: () => _selectDate(),
    ),
  ],
)
```

#### 날짜 네비게이션
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: () => _previousDay(),
    ),
    Text(
      _formatDate(selectedDate), // "1월 5일 (목)"
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: () => _nextDay(),
    ),
  ],
)
```

#### 타임라인 뷰
```dart
ListView.builder(
  itemCount: 24, // 00:00 ~ 23:00
  itemBuilder: (context, hour) {
    final eventsAtThisHour = _getEventsAtHour(hour);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시간 라벨
        SizedBox(
          width: 60,
          child: Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),

        // 구분선 + 이벤트
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Divider(),
              ...eventsAtThisHour.map((event) =>
                _buildTimelineEventTile(event)
              ),
            ],
          ),
        ),
      ],
    );
  },
)
```

#### 타임라인 이벤트 타일
```dart
Widget _buildTimelineEventTile(Event event) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 4),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _getStatusColor(event.status).withOpacity(0.1),
      border: Border(
        left: BorderSide(
          color: _getStatusColor(event.status),
          width: 4,
        ),
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          event.location,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}
```

---

## 3. Open Timingle

### 파일 경로
```
lib/features/open_timingle/presentation/pages/open_timingle_page.dart
lib/features/open_timingle/presentation/widgets/open_slot_card.dart
```

### 레이아웃
```
┌────────────────────────────────────┐
│ Open Timingle           🔍         │ ← 상단 앱바
├────────────────────────────────────┤
│ [지역: 강남] ▼  [서비스: 전체] ▼  │ ← 필터
├────────────────────────────────────┤
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 🏋️ PT 수업                     │ │ ← 오픈 슬롯 카드
│ │ by 김트레이너                   │ │
│ │                                │ │
│ │ 🕐 1월 5일 (목) 오전 9:00      │ │
│ │ ⏱️ 60분 | 💰 50,000원          │ │
│ │ 📍 강남 피트니스                │ │
│ │                                │ │
│ │        [예약하기]               │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 💅 네일아트                     │ │
│ │ by 네일샵                       │ │
│ │ ...                            │ │
│ └────────────────────────────────┘ │
│                                    │
│          (스크롤 가능)              │
│                                    │
├────────────────────────────────────┤
│     [하단 네비게이션 바]            │
└────────────────────────────────────┘
```

### UI 요소

#### 필터 드롭다운
```dart
Row(
  children: [
    Expanded(
      child: DropdownButton<String>(
        value: selectedRegion,
        items: regions.map((region) =>
          DropdownMenuItem(
            value: region,
            child: Text(region),
          )
        ).toList(),
        onChanged: (value) => _filterByRegion(value),
      ),
    ),
    SizedBox(width: 16),
    Expanded(
      child: DropdownButton<String>(
        value: selectedService,
        items: serviceTypes.map((service) =>
          DropdownMenuItem(
            value: service,
            child: Text(service),
          )
        ).toList(),
        onChanged: (value) => _filterByService(value),
      ),
    ),
  ],
)
```

#### 오픈 슬롯 카드
```dart
Card(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 서비스 타입 + 제목
        Row(
          children: [
            Icon(Icons.fitness_center, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                slot.title, // "PT 수업"
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),

        Text(
          'by ${slot.businessUser.name}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 12),

        // 시간
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Text(_formatDateTime(slot.startTime)),
          ],
        ),
        SizedBox(height: 4),

        // 시간 + 가격
        Row(
          children: [
            Icon(Icons.timer, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Text('${slot.durationMinutes}분'),
            SizedBox(width: 16),
            Icon(Icons.attach_money, size: 16, color: Colors.grey),
            Text('${NumberFormat('#,###').format(slot.price)}원'),
          ],
        ),
        SizedBox(height: 4),

        // 위치
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Text(slot.location),
          ],
        ),
        SizedBox(height: 16),

        // 예약 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _bookSlot(slot.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('예약하기'),
          ),
        ),
      ],
    ),
  ),
)
```

---

## 4. Friends

### 파일 경로
```
lib/features/friends/presentation/pages/friends_page.dart
lib/features/friends/presentation/widgets/friend_tile.dart
```

### 레이아웃
```
┌────────────────────────────────────┐
│ Friends                 + 친구 추가 │ ← 상단 앱바
├────────────────────────────────────┤
│ 🔍 검색...                         │ ← 검색바
├────────────────────────────────────┤
│                                    │
│ 👤 [프로필]  홍길동                 │ ← 친구 타일
│              최근: 1월 3일 PT       │
│ ────────────────────────────────── │
│ 👤 [프로필]  김철수                 │
│              최근: 12월 28일 미팅   │
│ ────────────────────────────────── │
│ 👤 [프로필]  이영희                 │
│              최근: 12월 20일 점심   │
│ ────────────────────────────────── │
│                                    │
│          (스크롤 가능)              │
│                                    │
├────────────────────────────────────┤
│     [하단 네비게이션 바]            │
└────────────────────────────────────┘
```

### UI 요소

#### 상단 앱바
```dart
AppBar(
  title: Text('Friends'),
  actions: [
    IconButton(
      icon: Icon(Icons.person_add),
      onPressed: () => _addFriend(),
    ),
  ],
)
```

#### 검색바
```dart
TextField(
  decoration: InputDecoration(
    hintText: '검색...',
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: Color(0xFFF9FAFB), // Gray 50
  ),
  onChanged: (value) => _search(value),
)
```

#### 친구 타일
```dart
ListTile(
  leading: CircleAvatar(
    radius: 24,
    backgroundImage: NetworkImage(friend.profileImageUrl),
  ),
  title: Text(
    friend.displayName,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
  subtitle: Text(
    '최근: ${_formatRecentEvent(friend.lastEvent)}',
    style: TextStyle(
      fontSize: 14,
      color: Colors.grey,
    ),
  ),
  trailing: Icon(Icons.chevron_right),
  onTap: () => _openFriendProfile(friend.id),
)
```

---

## 5. Settings

### 파일 경로
```
lib/features/settings/presentation/pages/settings_page.dart
```

### 레이아웃
```
┌────────────────────────────────────┐
│ Settings                           │ ← 상단 앱바
├────────────────────────────────────┤
│                                    │
│ 👤 [큰 프로필 이미지]               │ ← 프로필 섹션
│     홍길동                          │
│     +82 10-1234-5678               │
│                                    │
├────────────────────────────────────┤
│ 계정                                │ ← 섹션 헤더
│ > 프로필 수정                       │
│ > 지역 설정                         │
│ > 관심사 설정                       │
├────────────────────────────────────┤
│ 알림                                │
│ > 알림 설정                         │
│ > 소리 및 진동                      │
├────────────────────────────────────┤
│ 일반                                │
│ > 약관 및 정책                      │
│ > 버전 정보 (v1.0.0)                │
│ > 로그아웃                          │
├────────────────────────────────────┤
│     [하단 네비게이션 바]            │
└────────────────────────────────────┘
```

### UI 요소

#### 프로필 섹션
```dart
Container(
  padding: EdgeInsets.all(24),
  child: Column(
    children: [
      CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(user.profileImageUrl),
      ),
      SizedBox(height: 16),
      Text(
        user.name,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 4),
      Text(
        user.phone,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    ],
  ),
)
```

#### 설정 항목
```dart
ListTile(
  leading: Icon(Icons.person_outline),
  title: Text('프로필 수정'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => _editProfile(),
)
```

---

## 6. 이벤트 상세/채팅

### 파일 경로
```
lib/features/timingle/presentation/pages/event_detail_page.dart
lib/features/timingle/presentation/widgets/chat_message.dart
```

### 레이아웃
```
┌────────────────────────────────────┐
│ < 9am -> 길동이              ⋮     │ ← 상단 앱바
├────────────────────────────────────┤
│ ┌────────────────────────────────┐ │
│ │ 📍 강남 피트니스                │ │ ← 이벤트 정보 카드
│ │ 🕐 1월 5일 (목) 오전 9:00      │ │
│ │ 👥 홍길동, 김철수 (확정 2/2)   │ │
│ │ [확정됨] ✅                     │ │
│ └────────────────────────────────┘ │
├────────────────────────────────────┤
│                                    │
│ ┌──────────────────┐              │ ← 시스템 메시지
│ │ 홍길동님이 이벤트를 │              │   (중앙 정렬)
│ │ 생성했습니다       │              │
│ │   10:00 AM        │              │
│ └──────────────────┘              │
│                                    │
│ ┌──────────────────────────┐      │ ← 상대방 메시지
│ │ 네, 9시에 뵙겠습니다!     │      │   (왼쪽 정렬)
│ │                  10:05 AM │      │
│ └──────────────────────────┘      │
│                                    │
│              ┌──────────────────┐  │ ← 내 메시지
│              │ 감사합니다!       │  │   (오른쪽 정렬)
│              │ 10:07 AM         │  │
│              └──────────────────┘  │
│                                    │
│ ┌──────────────────┐              │ ← 시스템 메시지
│ │ 김철수님이 참여를  │              │
│ │ 확인했습니다       │              │
│ │   10:10 AM        │              │
│ └──────────────────┘              │
│                                    │
│          (스크롤 가능)              │
│                                    │
├────────────────────────────────────┤
│ [메시지 입력...]            [전송] │ ← 메시지 입력창
└────────────────────────────────────┘
```

### UI 요소

#### 상단 앱바
```dart
AppBar(
  title: Text(event.title),
  actions: [
    PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(child: Text('이벤트 수정')),
        PopupMenuItem(child: Text('참여자 관리')),
        PopupMenuItem(child: Text('이벤트 취소')),
      ],
    ),
  ],
)
```

#### 이벤트 정보 카드
```dart
Card(
  margin: EdgeInsets.all(16),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.location_on),
            SizedBox(width: 8),
            Text(event.location),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time),
            SizedBox(width: 8),
            Text(_formatDateTime(event.startTime)),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.people),
            SizedBox(width: 8),
            Text('${_getParticipantNames()} (확정 ${event.confirmedCount}/${event.totalParticipants})'),
          ],
        ),
        SizedBox(height: 12),
        _buildStatusBadge(event.status),
      ],
    ),
  ),
)
```

#### 채팅 메시지 (내 메시지)
```dart
Align(
  alignment: Alignment.centerRight,
  child: Container(
    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Color(0xFF3B82F6), // Accent Blue
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(4),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    ),
  ),
)
```

#### 채팅 메시지 (상대방 메시지)
```dart
Align(
  alignment: Alignment.centerLeft,
  child: Container(
    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Color(0xFFF3F4F6), // Gray 100
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(16),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.senderName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF1F2937), // Gray 800
          ),
        ),
        SizedBox(height: 4),
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  ),
)
```

#### 시스템 메시지
```dart
Center(
  child: Container(
    margin: EdgeInsets.symmetric(vertical: 8),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Color(0xFFF9FAFB), // Gray 50
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Text(
          message.content, // "홍길동님이 이벤트를 생성했습니다"
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  ),
)
```

#### 메시지 입력창
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    border: Border(
      top: BorderSide(color: Color(0xFFE5E7EB)), // Gray 200
    ),
  ),
  child: Row(
    children: [
      Expanded(
        child: TextField(
          controller: _messageController,
          decoration: InputDecoration(
            hintText: '메시지 입력...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            filled: true,
            fillColor: Color(0xFFF9FAFB), // Gray 50
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          onChanged: (value) => _onTyping(),
        ),
      ),
      SizedBox(width: 8),
      IconButton(
        icon: Icon(Icons.send, color: Color(0xFF3B82F6)),
        onPressed: () => _sendMessage(),
      ),
    ],
  ),
)
```

---

## 공통 컴포넌트

### 로딩 인디케이터
```dart
Center(
  child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(
      Color(0xFF3B82F6), // Accent Blue
    ),
  ),
)
```

### 빈 상태 메시지
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.inbox,
        size: 64,
        color: Colors.grey,
      ),
      SizedBox(height: 16),
      Text(
        '아직 이벤트가 없습니다',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    ],
  ),
)
```

### 에러 메시지
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.error_outline,
        size: 64,
        color: Color(0xFFEF4444), // Error Red
      ),
      SizedBox(height: 16),
      Text(
        '오류가 발생했습니다',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
      SizedBox(height: 8),
      ElevatedButton(
        onPressed: () => _retry(),
        child: Text('다시 시도'),
      ),
    ],
  ),
)
```

---

**Version**: 1.0
**최종 업데이트**: 2025-01-01
**참조**: [BRAND.md](BRAND.md), [API.md](API.md)
