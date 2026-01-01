# Phase 3: Flutter 앱 구현 (Week 3)

**목표**: Flutter Clean Architecture + Riverpod로 모바일 앱 구현

**소요 시간**: 5-7일

**상태**: ✅ 완료 (2025-01-01)

**완료 조건**:
- ✅ Flutter 프로젝트 구조 생성 (Clean Architecture)
- ✅ Riverpod 의존성 주입 설정
- ✅ 로그인 화면 구현 (전화번호 인증)
- ✅ Timingle (이벤트 목록) 화면 구현
- ✅ 채팅 화면 구현 (WebSocket 실시간 연동)
- ✅ Settings 화면 구현
- ✅ 다국어(i18n) 및 시간대(timezone) 처리
- ✅ GoRouter 라우팅 설정

---

## 📋 사전 준비사항

### 완료 확인
- [x] PHASE_1_BACKEND_CORE.md 완료
- [x] PHASE_2_REALTIME.md 완료
- [x] Backend API 서버 실행 중 (http://localhost:8080)
- [x] Flutter SDK 설치 완료 (v3.38.5)

### 확인 명령
```bash
# Flutter 버전 확인
flutter --version  # Flutter 3.24.0 이상, Dart 3.5.0 이상

# Flutter Doctor
flutter doctor

# Backend API 확인
curl http://localhost:8080/health
```

---

## 🚀 Step 1: Flutter 프로젝트 생성

### 1.1 프로젝트 생성
```bash
cd /home/khchoi/projects/timingle2

# Flutter 프로젝트 생성
flutter create frontend --org com.timingle --platforms android,ios

cd frontend
```

### 1.2 디렉토리 구조 생성 (Clean Architecture)
```bash
# features 디렉토리 생성
mkdir -p lib/features/{auth,timingle,timeline,open_timingle,friends,settings}/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{pages,widgets,providers}}

# core 디렉토리 생성
mkdir -p lib/core/{constants,error,network,usecases,utils,di}

# assets 디렉토리 생성
mkdir -p assets/{images,translations}

# 구조 확인
tree lib -L 3 -d
```

**예상 구조**:
```
lib/
├── core/
│   ├── constants/      # 상수, 색상, 테마
│   ├── error/          # 에러 정의
│   ├── network/        # API 클라이언트, WebSocket
│   ├── usecases/       # UseCase 추상 클래스
│   ├── utils/          # 유틸리티 (timezone, i18n)
│   └── di/             # 의존성 주입 (Riverpod Providers)
├── features/
│   ├── auth/           # 인증 (로그인)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── timingle/       # 이벤트 목록
│   ├── timeline/       # 타임라인 뷰
│   ├── open_timingle/  # 오픈 예약
│   ├── friends/        # 친구 목록
│   └── settings/       # 설정
└── main.dart
```

### 1.3 pubspec.yaml 업데이트
```bash
cat > pubspec.yaml << 'EOF'
name: frontend
description: timingle - 약속이 대화가 되는 앱
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management & DI
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Network
  dio: ^5.4.0
  retrofit: ^4.1.0
  pretty_dio_logger: ^1.3.1

  # WebSocket
  web_socket_channel: ^2.4.0

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2

  # Utilities
  dartz: ^0.10.1              # Either (성공/실패)
  freezed_annotation: ^2.4.1  # Immutable 모델
  json_annotation: ^4.8.1
  equatable: ^2.0.5           # Value 비교

  # UI
  go_router: ^13.0.0          # 라우팅
  flutter_svg: ^2.0.9         # SVG 지원
  cached_network_image: ^3.3.1 # 이미지 캐싱

  # i18n & Timezone
  intl: ^0.19.0
  easy_localization: ^3.0.5
  timezone: ^0.9.2

  # Auth
  google_sign_in: ^6.2.1
  flutter_secure_storage: ^9.0.0

  # Utils
  uuid: ^4.3.3
  timeago: ^3.6.0             # "2분 전" 등

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

  # Code Generation
  build_runner: ^2.4.8
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  retrofit_generator: ^8.1.0
  hive_generator: ^2.0.1
  riverpod_generator: ^2.4.0
  riverpod_lint: ^2.3.10

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/translations/

  fonts:
    - family: Pretendard
      fonts:
        - asset: fonts/Pretendard-Regular.ttf
        - asset: fonts/Pretendard-Bold.ttf
          weight: 700
EOF

# 의존성 설치
flutter pub get
```

---

## 🎨 Step 2: Core 설정 (Constants, Theme, Network)

### 2.1 lib/core/constants/app_colors.dart
```bash
cat > lib/core/constants/app_colors.dart << 'EOF'
import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF2E4A8F);      // 진한 네이비 블루
  static const Color secondaryBlue = Color(0xFF5EC4E8);    // 밝은 하늘색
  static const Color accentBlue = Color(0xFF3B82F6);       // 포인트 버튼
  static const Color purple = Color(0xFF8B5CF6);           // 추천, 특별 강조

  // Status Colors
  static const Color warningYellow = Color(0xFFFBBF24);    // 미확정 상태
  static const Color success = Color(0xFF10B981);          // 확정
  static const Color error = Color(0xFFEF4444);            // 취소

  // Neutral Colors
  static const Color grayLight = Color(0xFFE5E7EB);        // 카드 배경
  static const Color grayMedium = Color(0xFF9CA3AF);       // 부가 정보
  static const Color grayDark = Color(0xFF374151);         // 텍스트
  static const Color black = Color(0xFF111827);
  static const Color white = Color(0xFFFFFFFF);

  // Event Status Colors
  static const Color statusProposed = warningYellow;
  static const Color statusConfirmed = success;
  static const Color statusCanceled = error;
  static const Color statusDone = grayMedium;
}
EOF
```

### 2.2 lib/core/constants/app_theme.dart
```bash
cat > lib/core/constants/app_theme.dart << 'EOF'
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryBlue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      secondary: AppColors.secondaryBlue,
    ),
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
      centerTitle: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentBlue,
      foregroundColor: AppColors.white,
    ),
    cardTheme: CardTheme(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black),
      bodyLarge: TextStyle(fontSize: 14, color: AppColors.grayDark),
      bodyMedium: TextStyle(fontSize: 12, color: AppColors.grayMedium),
    ),
    fontFamily: 'Pretendard',
  );

  // Dark Theme (나중에 추가)
  static ThemeData darkTheme = ThemeData.dark();
}
EOF
```

### 2.3 lib/core/network/api_client.dart
```bash
cat > lib/core/network/api_client.dart << 'EOF'
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage storage;

  ApiClient({
    required String baseUrl,
    required this.storage,
  }) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptors
    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_languageInterceptor());
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));
  }

  // 인증 Interceptor
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        // 401 Unauthorized -> Refresh Token 시도
        if (e.response?.statusCode == 401) {
          final refreshToken = await storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              // Refresh Token API 호출
              final response = await dio.post('/api/auth/refresh', data: {
                'refresh_token': refreshToken,
              });

              // 새 토큰 저장
              final newAccessToken = response.data['access_token'];
              final newRefreshToken = response.data['refresh_token'];
              await storage.write(key: 'access_token', value: newAccessToken);
              await storage.write(key: 'refresh_token', value: newRefreshToken);

              // 원래 요청 재시도
              final opts = e.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(opts);
              return handler.resolve(retryResponse);
            } catch (_) {
              // Refresh 실패 -> 로그아웃
              await storage.deleteAll();
              handler.reject(e);
            }
          }
        }
        handler.next(e);
      },
    );
  }

  // 언어 Interceptor
  InterceptorsWrapper _languageInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // TODO: 사용자 설정 언어 가져오기
        options.headers['Accept-Language'] = 'ko'; // 기본값
        handler.next(options);
      },
    );
  }
}
EOF
```

### 2.4 lib/core/network/websocket_client.dart
```bash
cat > lib/core/network/websocket_client.dart << 'EOF'
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  final String baseUrl;
  final String accessToken;
  final int eventId;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  WebSocketClient({
    required this.baseUrl,
    required this.accessToken,
    required this.eventId,
  });

  void connect() {
    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl/ws?event_id=$eventId');

    _channel = WebSocketChannel.connect(
      uri,
      protocols: ['Bearer', accessToken],
    );

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message as String);
        _messageController.add(data);
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket closed');
      },
    );
  }

  void sendMessage(String message, {String? replyTo}) {
    if (_channel != null) {
      final data = {
        'message': message,
        if (replyTo != null) 'reply_to': replyTo,
      };
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _messageController.close();
  }
}
EOF
```

### 2.5 lib/core/utils/timezone_helper.dart
```bash
cat > lib/core/utils/timezone_helper.dart << 'EOF'
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class TimezoneHelper {
  // UTC를 로컬 시간대로 변환
  static DateTime utcToLocal(DateTime utcTime) {
    return utcTime.toLocal();
  }

  // 로컬 시간을 UTC로 변환 (서버 전송용)
  static DateTime localToUtc(DateTime localTime) {
    return localTime.toUtc();
  }

  // RFC3339 형식으로 포맷 (서버 전송용)
  static String toRFC3339(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  // 사용자 친화적 표시 (로컬 시간대)
  static String formatForUser(DateTime utcTime, String locale) {
    final local = utcTime.toLocal();

    if (locale == 'ko') {
      return DateFormat('yyyy년 M월 d일 a h시 m분', locale).format(local);
    } else {
      return DateFormat('MMM d, yyyy h:mm a', locale).format(local);
    }
  }

  // 짧은 형식 (카드용)
  static String formatShort(DateTime utcTime, String locale) {
    final local = utcTime.toLocal();

    if (locale == 'ko') {
      return DateFormat('M월 d일 a h시', locale).format(local);
    } else {
      return DateFormat('MMM d, h a', locale).format(local);
    }
  }

  // 상대 시간 ("2분 전", "1시간 후")
  static String timeAgo(DateTime utcTime, String locale) {
    final local = utcTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inSeconds < 60) {
      return locale == 'ko' ? '방금 전' : 'just now';
    } else if (difference.inMinutes < 60) {
      return locale == 'ko'
          ? '${difference.inMinutes}분 전'
          : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return locale == 'ko'
          ? '${difference.inHours}시간 전'
          : '${difference.inHours}h ago';
    } else {
      return formatShort(utcTime, locale);
    }
  }
}
EOF
```

---

## 📦 Step 3: Domain Layer (Entities, Repositories, UseCases)

### 3.1 lib/features/auth/domain/entities/user.dart
```bash
cat > lib/features/auth/domain/entities/user.dart << 'EOF'
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String phone;
  final String name;
  final String? email;
  final String? profileImageUrl;
  final String? region;
  final List<String> interests;
  final String timezone;
  final String language;
  final String role; // USER, BUSINESS

  const User({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    this.profileImageUrl,
    this.region,
    this.interests = const [],
    this.timezone = 'UTC',
    this.language = 'ko',
    this.role = 'USER',
  });

  @override
  List<Object?> get props => [
        id,
        phone,
        name,
        email,
        profileImageUrl,
        region,
        interests,
        timezone,
        language,
        role,
      ];
}
EOF
```

### 3.2 lib/features/timingle/domain/entities/event.dart
```bash
cat > lib/features/timingle/domain/entities/event.dart << 'EOF'
import 'package:equatable/equatable.dart';

enum EventStatus {
  proposed,
  confirmed,
  canceled,
  done;

  String get displayName {
    switch (this) {
      case EventStatus.proposed:
        return 'Proposed';
      case EventStatus.confirmed:
        return 'Confirmed';
      case EventStatus.canceled:
        return 'Canceled';
      case EventStatus.done:
        return 'Done';
    }
  }
}

class Event extends Equatable {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final int creatorId;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.creatorId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        location,
        creatorId,
        status,
        createdAt,
        updatedAt,
      ];
}
EOF
```

### 3.3 lib/features/timingle/domain/repositories/event_repository.dart
```bash
cat > lib/features/timingle/domain/repositories/event_repository.dart << 'EOF'
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';

abstract class EventRepository {
  Future<Either<Failure, List<Event>>> getEvents();
  Future<Either<Failure, Event>> getEvent(int eventId);
  Future<Either<Failure, Event>> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<int> participantIds = const [],
  });
  Future<Either<Failure, void>> updateEvent(int eventId, Map<String, dynamic> updates);
  Future<Either<Failure, void>> deleteEvent(int eventId);
  Future<Either<Failure, void>> confirmParticipation(int eventId);
}
EOF
```

### 3.4 lib/core/error/failures.dart
```bash
cat > lib/core/error/failures.dart << 'EOF'
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
EOF
```

### 3.5 lib/features/timingle/domain/usecases/get_events_usecase.dart
```bash
cat > lib/features/timingle/domain/usecases/get_events_usecase.dart << 'EOF'
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventsUseCase {
  final EventRepository repository;

  GetEventsUseCase(this.repository);

  Future<Either<Failure, List<Event>>> call() async {
    return await repository.getEvents();
  }
}
EOF
```

---

## 🗄️ Step 4: Data Layer (Models, DataSources, Repository 구현)

### 4.1 lib/features/timingle/data/models/event_model.dart
```bash
cat > lib/features/timingle/data/models/event_model.dart << 'EOF'
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/event.dart';

part 'event_model.g.dart';

@JsonSerializable()
class EventModel {
  final int id;
  final String title;
  final String? description;
  @JsonKey(name: 'start_time')
  final String startTime; // RFC3339
  @JsonKey(name: 'end_time')
  final String endTime;
  final String? location;
  @JsonKey(name: 'creator_id')
  final int creatorId;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.creatorId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  // Domain Entity로 변환
  Event toEntity() {
    return Event(
      id: id,
      title: title,
      description: description,
      startTime: DateTime.parse(startTime),
      endTime: DateTime.parse(endTime),
      location: location,
      creatorId: creatorId,
      status: _parseStatus(status),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  EventStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PROPOSED':
        return EventStatus.proposed;
      case 'CONFIRMED':
        return EventStatus.confirmed;
      case 'CANCELED':
        return EventStatus.canceled;
      case 'DONE':
        return EventStatus.done;
      default:
        return EventStatus.proposed;
    }
  }
}
EOF
```

### 4.2 lib/features/timingle/data/datasources/event_remote_datasource.dart
```bash
cat > lib/features/timingle/data/datasources/event_remote_datasource.dart << 'EOF'
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/event_model.dart';

part 'event_remote_datasource.g.dart';

@RestApi()
abstract class EventRemoteDataSource {
  factory EventRemoteDataSource(Dio dio, {String baseUrl}) =
      _EventRemoteDataSource;

  @GET('/api/events')
  Future<HttpResponse<Map<String, dynamic>>> getEvents();

  @GET('/api/events/{id}')
  Future<HttpResponse<EventModel>> getEvent(@Path('id') int eventId);

  @POST('/api/events')
  Future<HttpResponse<EventModel>> createEvent(@Body() Map<String, dynamic> body);

  @PATCH('/api/events/{id}')
  Future<HttpResponse<void>> updateEvent(
    @Path('id') int eventId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/events/{id}')
  Future<HttpResponse<void>> deleteEvent(@Path('id') int eventId);

  @POST('/api/events/{id}/confirm')
  Future<HttpResponse<void>> confirmParticipation(@Path('id') int eventId);
}
EOF
```

### 4.3 lib/features/timingle/data/repositories/event_repository_impl.dart
```bash
cat > lib/features/timingle/data/repositories/event_repository_impl.dart << 'EOF'
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;

  EventRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Event>>> getEvents() async {
    try {
      final response = await remoteDataSource.getEvents();
      final List<dynamic> eventsJson = response.data['events'];
      final events = eventsJson
          .map((json) => EventModel.fromJson(json).toEntity())
          .toList();
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Event>> getEvent(int eventId) async {
    try {
      final response = await remoteDataSource.getEvent(eventId);
      return Right(response.data.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Event>> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<int> participantIds = const [],
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'start_time': TimezoneHelper.toRFC3339(startTime),
        'end_time': TimezoneHelper.toRFC3339(endTime),
        'location': location,
        'participant_ids': participantIds,
      };

      final response = await remoteDataSource.createEvent(body);
      return Right(response.data.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateEvent(
      int eventId, Map<String, dynamic> updates) async {
    try {
      await remoteDataSource.updateEvent(eventId, updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(int eventId) async {
    try {
      await remoteDataSource.deleteEvent(eventId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmParticipation(int eventId) async {
    try {
      await remoteDataSource.confirmParticipation(eventId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
EOF
```

---

## 🔌 Step 5: Riverpod Providers (의존성 주입)

### 5.1 lib/core/di/providers.dart
```bash
cat > lib/core/di/providers.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../features/timingle/data/datasources/event_remote_datasource.dart';
import '../../features/timingle/data/repositories/event_repository_impl.dart';
import '../../features/timingle/domain/repositories/event_repository.dart';
import '../../features/timingle/domain/usecases/get_events_usecase.dart';

// Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  const baseUrl = 'http://localhost:8080'; // TODO: 환경변수로 관리
  final storage = ref.read(secureStorageProvider);
  return ApiClient(baseUrl: baseUrl, storage: storage);
});

// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  return ref.read(apiClientProvider).dio;
});

// Data Source Provider
final eventRemoteDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  final dio = ref.read(dioProvider);
  return EventRemoteDataSource(dio);
});

// Repository Provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final remoteDataSource = ref.read(eventRemoteDataSourceProvider);
  return EventRepositoryImpl(remoteDataSource: remoteDataSource);
});

// UseCase Provider
final getEventsUseCaseProvider = Provider<GetEventsUseCase>((ref) {
  final repository = ref.read(eventRepositoryProvider);
  return GetEventsUseCase(repository);
});
EOF
```

---

## 🎨 Step 6: Presentation Layer (UI - Timingle 화면)

### 6.1 lib/features/timingle/presentation/providers/event_provider.dart
```bash
cat > lib/features/timingle/presentation/providers/event_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/event.dart';

// Event State Notifier
class EventNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final GetEventsUseCase getEventsUseCase;

  EventNotifier(this.getEventsUseCase) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    final result = await getEventsUseCase();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (events) => state = AsyncValue.data(events),
    );
  }

  Future<void> refresh() async {
    await loadEvents();
  }
}

// Event Provider
final eventNotifierProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<List<Event>>>((ref) {
  final useCase = ref.read(getEventsUseCaseProvider);
  return EventNotifier(useCase);
});
EOF
```

### 6.2 lib/features/timingle/presentation/pages/timingle_page.dart
```bash
cat > lib/features/timingle/presentation/pages/timingle_page.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../domain/entities/event.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';

class TiminglePage extends ConsumerStatefulWidget {
  const TiminglePage({super.key});

  @override
  ConsumerState<TiminglePage> createState() => _TiminglePageState();
}

class _TiminglePageState extends ConsumerState<TiminglePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timingle'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          indicatorColor: AppColors.accentBlue,
          tabs: [
            Tab(text: 'timingle.filter_all'.tr()),
            Tab(text: 'timingle.filter_upcoming'.tr()),
            Tab(text: 'timingle.filter_done'.tr()),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(eventNotifierProvider.notifier).refresh();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildEventList(eventsState, null),
            _buildEventList(eventsState, (e) =>
                e.status == EventStatus.proposed ||
                e.status == EventStatus.confirmed),
            _buildEventList(
                eventsState, (e) => e.status == EventStatus.done),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createEvent(context),
        tooltip: 'timingle.create_event'.tr(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList(
    AsyncValue<List<Event>> eventsState,
    bool Function(Event)? filter,
  ) {
    return eventsState.when(
      data: (events) {
        final filteredEvents =
            filter != null ? events.where(filter).toList() : events;

        if (filteredEvents.isEmpty) {
          return Center(
            child: Text('timingle.no_events'.tr()),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            final event = filteredEvents[index];
            return EventCard(
              event: event,
              onTap: () => _openEventDetail(context, event.id),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('errors.network_error'.tr()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(eventNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _openEventDetail(BuildContext context, int eventId) {
    // TODO: Navigate to event detail
    Navigator.of(context).pushNamed('/event/$eventId');
  }

  void _createEvent(BuildContext context) {
    // TODO: Navigate to create event
    Navigator.of(context).pushNamed('/event/create');
  }
}
EOF
```

### 6.3 lib/features/timingle/presentation/widgets/event_card.dart
```bash
cat > lib/features/timingle/presentation/widgets/event_card.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../domain/entities/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status Badge
                  _buildStatusBadge(event.status),
                  const Spacer(),
                  // Time
                  Text(
                    TimezoneHelper.formatShort(event.startTime, locale),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grayMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (event.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.grayMedium),
                    const SizedBox(width: 4),
                    Text(
                      event.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grayMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(EventStatus status) {
    Color color;
    String text;

    switch (status) {
      case EventStatus.proposed:
        color = AppColors.statusProposed;
        text = 'event.status_proposed'.tr();
        break;
      case EventStatus.confirmed:
        color = AppColors.statusConfirmed;
        text = 'event.status_confirmed'.tr();
        break;
      case EventStatus.canceled:
        color = AppColors.statusCanceled;
        text = 'event.status_canceled'.tr();
        break;
      case EventStatus.done:
        color = AppColors.statusDone;
        text = 'event.status_done'.tr();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
EOF
```

---

## 🌐 Step 7: 다국어(i18n) 설정

### 7.1 assets/translations/ko.json
```bash
cat > assets/translations/ko.json << 'EOF'
{
  "app_name": "timingle",
  "login": {
    "title": "로그인",
    "google_login": "Google로 계속하기",
    "phone_login": "전화번호로 로그인"
  },
  "timingle": {
    "title": "Timingle",
    "filter_all": "전체",
    "filter_upcoming": "예정",
    "filter_done": "완료",
    "no_events": "약속이 없습니다",
    "create_event": "새 약속 만들기"
  },
  "event": {
    "status_proposed": "제안됨",
    "status_confirmed": "확정됨",
    "status_canceled": "취소됨",
    "status_done": "완료"
  },
  "errors": {
    "network_error": "네트워크 오류가 발생했습니다",
    "login_failed": "로그인에 실패했습니다"
  }
}
EOF
```

### 7.2 assets/translations/en.json
```bash
cat > assets/translations/en.json << 'EOF'
{
  "app_name": "timingle",
  "login": {
    "title": "Login",
    "google_login": "Continue with Google",
    "phone_login": "Login with Phone"
  },
  "timingle": {
    "title": "Timingle",
    "filter_all": "All",
    "filter_upcoming": "Upcoming",
    "filter_done": "Done",
    "no_events": "No events",
    "create_event": "Create Event"
  },
  "event": {
    "status_proposed": "Proposed",
    "status_confirmed": "Confirmed",
    "status_canceled": "Canceled",
    "status_done": "Done"
  },
  "errors": {
    "network_error": "Network error occurred",
    "login_failed": "Login failed"
  }
}
EOF
```

---

## 🚀 Step 8: main.dart 및 앱 실행

### 8.1 lib/main.dart
```bash
cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/constants/app_theme.dart';
import 'features/timingle/presentation/pages/timingle_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 시간대 초기화
  tz.initializeTimeZones();

  // 다국어 초기화
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
      home: const TiminglePage(),
    );
  }
}
EOF
```

### 8.2 코드 생성 실행
```bash
cd frontend

# JSON Serialization 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 또는 watch 모드 (파일 변경 시 자동 생성)
flutter pub run build_runner watch
```

### 8.3 앱 실행
```bash
# Android Emulator 또는 iOS Simulator 실행 후
flutter run

# 또는 특정 디바이스 지정
flutter devices
flutter run -d <device-id>
```

---

## ✅ 완료 체크리스트

### Phase 3 완료 조건
- [x] Flutter 프로젝트 구조 생성 (Clean Architecture)
- [x] Riverpod Providers 설정 완료
- [x] Timingle 메인 화면 동작 확인
- [x] API 연동 성공 (이벤트 목록 조회)
- [x] 다국어 번역 파일 작성 (한국어/영어)
- [x] 시간대 로컬 변환 확인
- [x] 채팅 화면 및 WebSocket 연동 완료
- [x] Settings 화면 구현 완료

### 디버깅 팁
```bash
# 로그 확인
flutter logs

# 핫 리로드
r (in flutter run terminal)

# 핫 리스타트
R (in flutter run terminal)

# 의존성 문제 해결
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🎯 다음 단계

**Phase 3 완료 후**:
- ➡️ **PHASE_4_INTEGRATION.md**: 통합 테스트, E2E 테스트
- ➡️ **PHASE_5_DEPLOYMENT.md**: 배포 및 출시

**Phase 3 결과물**:
- Flutter Clean Architecture 앱 구현
- Riverpod 의존성 주입
- Timingle 메인 화면 (이벤트 목록/생성)
- 채팅 화면 (WebSocket 실시간 메시지)
- Settings 화면 (프로필, 알림, 앱 설정, 로그아웃)
- 다국어 번역 파일 (ko-KR, en-US)
- API 연동 완료

**추가 구현 예정** (PHASE_4에서 진행):
- Timeline 화면
- Open Timingle 화면
- Friends 화면
- Push 알림 연동

---

## 📁 구현된 파일 목록

### Core Layer
```
lib/core/
├── constants/
│   ├── app_colors.dart        # 브랜드 색상 정의
│   ├── api_constants.dart     # API 엔드포인트
│   └── app_constants.dart     # 앱 상수
├── di/
│   └── router.dart            # GoRouter 라우팅
├── error/
│   ├── failures.dart          # Failure 클래스
│   └── exceptions.dart        # Exception 클래스
├── network/
│   ├── api_client.dart        # Dio HTTP 클라이언트
│   ├── websocket_client.dart  # WebSocket 클라이언트
│   └── token_storage.dart     # 토큰 저장소
└── usecases/
    └── usecase.dart           # UseCase 추상 클래스
```

### Features
```
lib/features/
├── auth/                      # 인증 기능
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/
│   └── presentation/
│       ├── pages/login_page.dart
│       └── providers/auth_provider.dart
│
├── timingle/                  # 이벤트 목록
│   ├── data/
│   ├── domain/
│   └── presentation/
│       ├── pages/timingle_page.dart
│       ├── widgets/event_card.dart
│       └── providers/event_provider.dart
│
├── chat/                      # 채팅 기능
│   ├── data/
│   ├── domain/
│   └── presentation/
│       ├── pages/chat_page.dart
│       ├── widgets/
│       │   ├── message_bubble.dart
│       │   └── message_input.dart
│       └── providers/chat_provider.dart
│
└── settings/                  # 설정
    └── presentation/
        ├── pages/settings_page.dart
        └── widgets/settings_tile.dart
```

### Assets
```
assets/translations/
├── ko-KR.json                 # 한국어 번역
└── en-US.json                 # 영어 번역
```

---

**Phase 3 완료! 🎉 Flutter 앱 구현 완료!**
