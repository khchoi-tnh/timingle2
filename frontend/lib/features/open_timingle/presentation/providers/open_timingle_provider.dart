import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/open_slot.dart';

/// 오픈 타이밍글 상태
class OpenTimingleState {
  final List<OpenSlot> slots;
  final bool isLoading;
  final String? error;
  final String selectedCategory;
  final String searchQuery;

  const OpenTimingleState({
    this.slots = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory = '전체',
    this.searchQuery = '',
  });

  OpenTimingleState copyWith({
    List<OpenSlot>? slots,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return OpenTimingleState(
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// 필터링된 슬롯 목록
  List<OpenSlot> get filteredSlots {
    var result = slots;

    // 카테고리 필터
    if (selectedCategory != '전체') {
      result = result.where((s) => s.category == selectedCategory).toList();
    }

    // 검색어 필터
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((s) {
        return s.title.toLowerCase().contains(query) ||
            s.hostName.toLowerCase().contains(query) ||
            (s.description?.toLowerCase().contains(query) ?? false) ||
            (s.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
  }
}

/// 오픈 타이밍글 Notifier
class OpenTimingleNotifier extends StateNotifier<OpenTimingleState> {
  OpenTimingleNotifier() : super(const OpenTimingleState());

  /// 슬롯 목록 로드
  Future<void> loadSlots() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 실제 API 호출로 대체
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock 데이터
      final now = DateTime.now();
      final mockSlots = [
        OpenSlot(
          id: 1,
          hostId: 100,
          hostName: '김코치',
          title: '1:1 피트니스 PT',
          description: '개인 맞춤 운동 프로그램을 제공합니다',
          location: '강남 헬스장',
          startTime: now.add(const Duration(days: 1, hours: 10)),
          endTime: now.add(const Duration(days: 1, hours: 11)),
          maxParticipants: 1,
          currentParticipants: 0,
          isAvailable: true,
          price: 50000,
          category: '운동',
          tags: ['PT', '피트니스', '다이어트'],
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        OpenSlot(
          id: 2,
          hostId: 101,
          hostName: '이튜터',
          title: '영어 회화 수업',
          description: '원어민 수준의 영어 회화 레슨',
          location: '온라인 (Zoom)',
          startTime: now.add(const Duration(days: 1, hours: 14)),
          endTime: now.add(const Duration(days: 1, hours: 15)),
          maxParticipants: 3,
          currentParticipants: 1,
          isAvailable: true,
          price: 30000,
          category: '교육',
          tags: ['영어', '회화', '온라인'],
          createdAt: now.subtract(const Duration(hours: 12)),
        ),
        OpenSlot(
          id: 3,
          hostId: 102,
          hostName: '박상담사',
          title: '커리어 상담',
          description: '이직, 진로 고민 상담',
          location: '서울 강남역 카페',
          startTime: now.add(const Duration(days: 2, hours: 16)),
          endTime: now.add(const Duration(days: 2, hours: 17)),
          maxParticipants: 1,
          currentParticipants: 0,
          isAvailable: true,
          price: 40000,
          category: '상담',
          tags: ['커리어', '이직', '진로'],
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        OpenSlot(
          id: 4,
          hostId: 103,
          hostName: '최셰프',
          title: '홈 쿠킹 클래스',
          description: '간단하고 맛있는 집밥 요리',
          location: '마포구 요리 스튜디오',
          startTime: now.add(const Duration(days: 3, hours: 11)),
          endTime: now.add(const Duration(days: 3, hours: 13)),
          maxParticipants: 5,
          currentParticipants: 3,
          isAvailable: true,
          price: 45000,
          category: '취미',
          tags: ['요리', '쿠킹클래스', '집밥'],
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        OpenSlot(
          id: 5,
          hostId: 104,
          hostName: '정네일',
          title: '네일 아트',
          description: '트렌디한 네일 디자인',
          location: '홍대 네일샵',
          startTime: now.add(const Duration(days: 1, hours: 15)),
          endTime: now.add(const Duration(days: 1, hours: 16, minutes: 30)),
          maxParticipants: 1,
          currentParticipants: 0,
          isAvailable: true,
          price: 35000,
          category: '뷰티',
          tags: ['네일', '네일아트', '뷰티'],
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ];

      state = state.copyWith(slots: mockSlots, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '슬롯을 불러오는데 실패했습니다',
      );
    }
  }

  /// 카테고리 선택
  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// 검색어 변경
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 슬롯 예약
  Future<bool> bookSlot(int slotId) async {
    try {
      // TODO: 실제 API 호출로 대체
      await Future.delayed(const Duration(milliseconds: 500));

      // 예약 성공 시 목록 갱신
      await loadSlots();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider 정의
final openTimingleProvider =
    StateNotifierProvider<OpenTimingleNotifier, OpenTimingleState>((ref) {
  return OpenTimingleNotifier();
});

/// 카테고리 목록
final categoriesProvider = Provider<List<String>>((ref) {
  return ['전체', '운동', '교육', '상담', '취미', '뷰티', '비즈니스', '기타'];
});
