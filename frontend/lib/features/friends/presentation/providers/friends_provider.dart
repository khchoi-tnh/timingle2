import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/friend.dart';

/// 친구 목록 상태
class FriendsState {
  final List<Friend> friends;
  final List<Friend> pendingRequests;
  final List<Friend> receivedRequests;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const FriendsState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.receivedRequests = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  FriendsState copyWith({
    List<Friend>? friends,
    List<Friend>? pendingRequests,
    List<Friend>? receivedRequests,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// 필터링된 친구 목록
  List<Friend> get filteredFriends {
    if (searchQuery.isEmpty) return friends;

    final query = searchQuery.toLowerCase();
    return friends.where((f) {
      return f.name.toLowerCase().contains(query) ||
          (f.phone?.contains(query) ?? false);
    }).toList();
  }

  /// 전체 친구 수
  int get totalFriends => friends.length;

  /// 받은 요청 수
  int get receivedRequestCount => receivedRequests.length;
}

/// 친구 Notifier
class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier() : super(const FriendsState());

  /// 친구 목록 로드
  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 실제 API 호출로 대체
      await Future.delayed(const Duration(milliseconds: 500));

      final now = DateTime.now();
      final mockFriends = [
        Friend(
          id: 1,
          name: '김철수',
          phone: '010-1234-5678',
          status: FriendStatus.accepted,
          lastEventDate: now.subtract(const Duration(days: 3)),
          eventCount: 5,
          createdAt: now.subtract(const Duration(days: 30)),
        ),
        Friend(
          id: 2,
          name: '이영희',
          phone: '010-2345-6789',
          status: FriendStatus.accepted,
          lastEventDate: now.subtract(const Duration(days: 7)),
          eventCount: 3,
          createdAt: now.subtract(const Duration(days: 60)),
        ),
        Friend(
          id: 3,
          name: '박민수',
          phone: '010-3456-7890',
          status: FriendStatus.accepted,
          lastEventDate: now.subtract(const Duration(days: 14)),
          eventCount: 8,
          createdAt: now.subtract(const Duration(days: 90)),
        ),
        Friend(
          id: 4,
          name: '정수진',
          phone: '010-4567-8901',
          status: FriendStatus.accepted,
          eventCount: 1,
          createdAt: now.subtract(const Duration(days: 10)),
        ),
        Friend(
          id: 5,
          name: '최지훈',
          phone: '010-5678-9012',
          status: FriendStatus.accepted,
          lastEventDate: now.subtract(const Duration(days: 1)),
          eventCount: 12,
          createdAt: now.subtract(const Duration(days: 120)),
        ),
      ];

      final mockPending = [
        Friend(
          id: 10,
          name: '김신청',
          phone: '010-9999-1111',
          status: FriendStatus.pending,
          eventCount: 0,
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
      ];

      final mockReceived = [
        Friend(
          id: 20,
          name: '이요청',
          phone: '010-8888-2222',
          status: FriendStatus.received,
          eventCount: 0,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        Friend(
          id: 21,
          name: '박요청',
          phone: '010-7777-3333',
          status: FriendStatus.received,
          eventCount: 0,
          createdAt: now.subtract(const Duration(hours: 12)),
        ),
      ];

      state = state.copyWith(
        friends: mockFriends,
        pendingRequests: mockPending,
        receivedRequests: mockReceived,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '친구 목록을 불러오는데 실패했습니다',
      );
    }
  }

  /// 검색어 변경
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 친구 요청 수락
  Future<bool> acceptRequest(int friendId) async {
    try {
      // TODO: 실제 API 호출
      await Future.delayed(const Duration(milliseconds: 300));

      final request = state.receivedRequests.firstWhere((f) => f.id == friendId);
      final updatedReceived =
          state.receivedRequests.where((f) => f.id != friendId).toList();
      final updatedFriends = [
        ...state.friends,
        Friend(
          id: request.id,
          name: request.name,
          phone: request.phone,
          status: FriendStatus.accepted,
          eventCount: 0,
          createdAt: DateTime.now(),
        ),
      ];

      state = state.copyWith(
        friends: updatedFriends,
        receivedRequests: updatedReceived,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 친구 요청 거절
  Future<bool> rejectRequest(int friendId) async {
    try {
      // TODO: 실제 API 호출
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedReceived =
          state.receivedRequests.where((f) => f.id != friendId).toList();
      state = state.copyWith(receivedRequests: updatedReceived);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 친구 삭제
  Future<bool> removeFriend(int friendId) async {
    try {
      // TODO: 실제 API 호출
      await Future.delayed(const Duration(milliseconds: 300));

      final updated = state.friends.where((f) => f.id != friendId).toList();
      state = state.copyWith(friends: updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 친구 요청 보내기
  Future<bool> sendRequest(String phone) async {
    try {
      // TODO: 실제 API 호출
      await Future.delayed(const Duration(milliseconds: 300));

      // 요청 성공 시 pending에 추가
      await loadFriends();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider 정의
final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier();
});
