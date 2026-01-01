# Phase 4: 통합 및 테스트 (Week 4)

**목표**: 남은 화면 구현, WebSocket 연동, 통합 테스트

**소요 시간**: 5-7일

**상태**: ✅ 완료 (2026-01-01)

**완료 조건**:
- ✅ Timeline 화면 구현 (캘린더 + 이벤트 리스트)
- ✅ Bottom Navigation Bar 구현 (5개 탭)
- ✅ WebSocket 실시간 채팅 연동 (PHASE 3에서 완료)
- ✅ Settings 화면 구현 (PHASE 3에서 완료)
- ✅ Open Timingle 화면 (오픈 예약 마켓플레이스)
- ✅ Friends 화면 (친구 목록 + 요청 관리)
- ⬜ E2E 시나리오 테스트 (PHASE 5에서 진행)

---

## 📋 사전 준비사항

### 완료 확인
- [x] PHASE_1_BACKEND_CORE.md 완료
- [x] PHASE_2_REALTIME.md 완료
- [x] PHASE_3_FLUTTER.md 완료
- [x] Backend API + WebSocket + Worker 실행 중
- [x] Flutter 앱 기본 동작 확인

---

## 🔐 Step 1: 로그인 화면 구현

### 1.1 lib/features/auth/presentation/pages/login_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 16),
              // App Name
              Text(
                'timingle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '약속이 대화가 되는 앱',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grayMedium,
                ),
              ),
              const SizedBox(height: 64),
              // Google Login Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: Image.asset('assets/images/google_logo.png', height: 24),
                label: Text('login.google_login'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.grayLight),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Phone Login Button
              OutlinedButton(
                onPressed: _isLoading ? null : _handlePhoneLogin,
                child: Text('login.phone_login'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final String? idToken = auth.idToken;

        // TODO: Backend API 호출 (POST /api/auth/google)
        // final response = await dio.post('/api/auth/google', data: {'id_token': idToken});
        // await storage.write(key: 'access_token', value: response.data['access_token']);
        // await storage.write(key: 'refresh_token', value: response.data['refresh_token']);

        // 로그인 성공 -> 메인 화면으로
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errors.login_failed'.tr())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePhoneLogin() async {
    // TODO: 전화번호 인증 화면으로 이동
    Navigator.of(context).pushNamed('/auth/phone');
  }
}
```

---

## 📅 Step 2: Timeline 화면 구현

### 2.1 lib/features/timeline/presentation/pages/timeline_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../timingle/domain/entities/event.dart';
import '../../../timingle/presentation/providers/event_provider.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.accentBlue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.secondaryBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          // Events for selected day
          Expanded(
            child: eventsState.when(
              data: (events) {
                final dayEvents = events.where((e) {
                  final eventDate = e.startTime.toLocal();
                  return isSameDay(eventDate, _selectedDay);
                }).toList();

                if (dayEvents.isEmpty) {
                  return Center(
                    child: Text('No events on this day'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    final event = dayEvents[index];
                    return _buildTimelineItem(event);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Event event) {
    final locale = context.locale.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            DateFormat('HH:mm').format(event.startTime.toLocal()),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        title: Text(event.title),
        subtitle: event.location != null ? Text(event.location!) : null,
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to event detail
        },
      ),
    );
  }
}
```

**pubspec.yaml에 추가**:
```yaml
dependencies:
  table_calendar: ^3.0.9
```

---

## 🎯 Step 3: Event Detail / Chat 화면 (WebSocket)

### 3.1 lib/features/timingle/presentation/pages/event_detail_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../domain/entities/event.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketClient? _wsClient;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _wsClient?.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectWebSocket() async {
    // TODO: Get access token from secure storage
    final accessToken = 'YOUR_ACCESS_TOKEN';

    _wsClient = WebSocketClient(
      baseUrl: 'http://localhost:8080',
      accessToken: accessToken,
      eventId: widget.eventId,
    );

    _wsClient!.connect();

    _wsClient!.messages.listen((message) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch event details from API
    final Event? event = null; // Replace with actual event

    return Scaffold(
      appBar: AppBar(
        title: Text(event?.title ?? 'Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Info Header
          if (event != null) _buildEventHeader(event),
          const Divider(),
          // Chat Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEventHeader(Event event) {
    final locale = context.locale.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.grayLight.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TimezoneHelper.formatForUser(event.startTime, locale),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grayMedium,
            ),
          ),
          const SizedBox(height: 4),
          if (event.location != null)
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.grayMedium),
                const SizedBox(width: 4),
                Text(event.location!),
              ],
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // TODO: Confirm participation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: Text('event.confirm_participation'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    // TODO: Get current user ID
    final currentUserId = 1;
    final senderId = message['sender_id'] as int;
    final isMe = senderId == currentUserId;

    final locale = context.locale.toString();
    final createdAt = DateTime.parse(message['created_at'] as String);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accentBlue : AppColors.grayLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message['sender_name'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isMe ? AppColors.white : AppColors.grayDark,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              message['message'] as String,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? AppColors.white : AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TimezoneHelper.timeAgo(createdAt, locale),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? AppColors.white.withOpacity(0.7)
                    : AppColors.grayMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.grayLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.grayLight.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: AppColors.accentBlue,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _wsClient?.sendMessage(text);
    _messageController.clear();
  }
}
```

---

## 🏠 Step 4: 하단 네비게이션 바 구현

### 4.1 lib/main.dart 업데이트 (Bottom Navigation)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/constants/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'features/timingle/presentation/pages/timingle_page.dart';
import 'features/timeline/presentation/pages/timeline_page.dart';
// import 'features/open_timingle/presentation/pages/open_timingle_page.dart';
// import 'features/friends/presentation/pages/friends_page.dart';
// import 'features/settings/presentation/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko', 'KR'),
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'timingle',
      theme: AppTheme.lightTheme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TiminglePage(),
    const TimelinePage(),
    const Placeholder(), // OpenTiminglePage(),
    const Placeholder(), // FriendsPage(),
    const Placeholder(), // SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.grayMedium,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Timingle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Open',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

---

## 🧪 Step 5: 통합 테스트

### 5.1 E2E 테스트 시나리오
```bash
cd frontend

# Integration test 디렉토리 생성
mkdir -p integration_test

cat > integration_test/app_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test', () {
    testWidgets('Full flow: Login -> Create Event -> Chat', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 로그인 화면 확인
      expect(find.text('timingle'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // TODO: Mock login
      // await tester.tap(find.text('Continue with Google'));
      // await tester.pumpAndSettle();

      // 2. Timingle 화면 확인
      expect(find.text('Timingle'), findsOneWidget);

      // 3. 새 이벤트 생성
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // TODO: Fill event form and submit

      // 4. 이벤트 상세 화면에서 채팅
      // TODO: Send message via WebSocket
    });
  });
}
EOF
```

**pubspec.yaml에 추가**:
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

**실행**:
```bash
flutter test integration_test/app_test.dart
```

---

## 🚀 Step 6: 성능 최적화

### 6.1 이미지 캐싱
```dart
// lib/core/widgets/cached_profile_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

class CachedProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const CachedProfileImage({
    super.key,
    this.imageUrl,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.grayLight,
        child: Icon(Icons.person, size: size / 2),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: size / 2,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.grayLight,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.grayLight,
        child: Icon(Icons.error, size: size / 2),
      ),
    );
  }
}
```

### 6.2 무한 스크롤 (Pagination)
```dart
// EventNotifier에 추가
class EventNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  // ...existing code...

  int _page = 1;
  bool _hasMore = true;

  Future<void> loadMore() async {
    if (!_hasMore) return;

    _page++;
    // TODO: Fetch events with pagination
    // final result = await getEventsUseCase(page: _page);
  }
}

// TiminglePage에서 사용
ScrollController _scrollController = ScrollController();

@override
void initState() {
  super.initState();
  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(eventNotifierProvider.notifier).loadMore();
    }
  });
}
```

---

## ✅ 완료 체크리스트

### Phase 4 완료 조건
- [ ] 로그인 화면 구현 (Google OAuth + 전화번호)
- [ ] Timeline 화면 구현 (Calendar + 일정 리스트)
- [ ] Event Detail/Chat 화면 구현 (WebSocket 연동)
- [ ] 하단 네비게이션 바 동작
- [ ] WebSocket 실시간 메시지 송수신 확인
- [ ] 다국어 전환 동작 (모든 화면)
- [ ] 시간대 로컬 변환 확인 (모든 시간 표시)
- [ ] E2E 테스트 시나리오 작성 및 실행
- [ ] 이미지 캐싱 적용
- [ ] 무한 스크롤 (Pagination) 구현
- [ ] 메모리 누수 확인 (`flutter analyze`)
- [ ] 빌드 성공 (Android APK + iOS IPA)

---

## 🎯 다음 단계

**Phase 4 완료 후**:
- ➡️ **PHASE_5_DEPLOYMENT.md**: 프로덕션 배포 및 출시

**Phase 4 결과물**:
- 전체 Flutter 앱 완성
- 실시간 채팅 동작 확인
- E2E 테스트 완료
- 성능 최적화 완료

**남은 작업** (PHASE_5):
- E2E 테스트 및 성능 최적화
- 프로덕션 배포 (Google Play + App Store)
- 모니터링 설정

---

## 📁 구현된 파일 목록

### Open Timingle Feature
```
lib/features/open_timingle/
├── domain/entities/
│   └── open_slot.dart                 # 오픈 슬롯 엔티티
├── presentation/
│   ├── pages/
│   │   └── open_timingle_page.dart    # 오픈 예약 메인 화면
│   ├── providers/
│   │   └── open_timingle_provider.dart # 상태 관리
│   └── widgets/
│       └── open_slot_card.dart        # 슬롯 카드 위젯
```

### Friends Feature
```
lib/features/friends/
├── domain/entities/
│   └── friend.dart                    # 친구 엔티티 + FriendStatus enum
├── presentation/
│   ├── pages/
│   │   └── friends_page.dart          # 친구 목록 메인 화면
│   ├── providers/
│   │   └── friends_provider.dart      # 상태 관리
│   └── widgets/
│       └── friend_tile.dart           # 친구 타일 + 요청 타일 위젯
```

### 주요 기능
- **Open Timingle**: 카테고리 필터, 검색, 예약하기, 가격 표시
- **Friends**: 친구 목록, 친구 요청 수락/거절, 친구 추가, 친구 삭제

---

**Phase 4 완료! 🎉 모든 5개 탭 화면 구현 완성!**
