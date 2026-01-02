import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/friend.dart';
import '../providers/friends_provider.dart';
import '../widgets/friend_tile.dart';

/// Friends 페이지 - 친구 목록
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsProvider.notifier).loadFriends();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(
              Icons.people,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Friends',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state.receivedRequestCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.receivedRequestCount}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: AppColors.primaryBlue),
            onPressed: () => _showAddFriendDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.grayMedium,
          indicatorColor: AppColors.primaryBlue,
          tabs: [
            Tab(text: '친구 ${state.totalFriends}'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('요청'),
                  if (state.receivedRequestCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.receivedRequestCount}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '이름 또는 전화번호 검색',
                hintStyle: const TextStyle(color: AppColors.grayMedium),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.grayMedium),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear, color: AppColors.grayMedium),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(friendsProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.grayLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                ref.read(friendsProvider.notifier).setSearchQuery(value);
              },
            ),
          ),

          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(state),
                _buildRequestsList(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(FriendsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: AppColors.grayDark)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(friendsProvider.notifier).loadFriends(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final friends = state.filteredFriends;

    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.grayMedium.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty ? '검색 결과가 없어요' : '아직 친구가 없어요',
              style: const TextStyle(fontSize: 16, color: AppColors.grayDark),
            ),
            const SizedBox(height: 8),
            const Text(
              '친구를 추가해보세요!',
              style: TextStyle(fontSize: 14, color: AppColors.grayMedium),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddFriendDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('친구 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(friendsProvider.notifier).loadFriends(),
      color: AppColors.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: friends.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final friend = friends[index];
          return FriendTile(
            friend: friend,
            onTap: () => _showFriendDetail(context, friend),
            onCreateEvent: () => _createEventWithFriend(friend),
            onMore: () => _showFriendOptions(context, friend),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(FriendsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    final received = state.receivedRequests;
    final pending = state.pendingRequests;

    if (received.isEmpty && pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: AppColors.grayMedium.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '친구 요청이 없어요',
              style: TextStyle(fontSize: 16, color: AppColors.grayDark),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 받은 요청
        if (received.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '받은 요청 ${received.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grayDark,
              ),
            ),
          ),
          ...received.map((friend) => FriendRequestTile(
                friend: friend,
                onAccept: () => _acceptRequest(friend),
                onReject: () => _rejectRequest(friend),
              )),
        ],

        // 보낸 요청
        if (pending.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '보낸 요청 ${pending.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grayDark,
              ),
            ),
          ),
          ...pending.map((friend) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.grayLight,
                  child: Text(
                    friend.name.isNotEmpty ? friend.name[0] : '?',
                    style: const TextStyle(color: AppColors.grayDark),
                  ),
                ),
                title: Text(friend.name),
                subtitle: const Text(
                  '수락 대기 중',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grayMedium,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    // TODO: 요청 취소
                  },
                  child: const Text(
                    '취소',
                    style: TextStyle(color: AppColors.grayDark),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '친구의 전화번호를 입력해주세요',
              style: TextStyle(color: AppColors.grayDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '010-1234-5678',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                final success =
                    await ref.read(friendsProvider.notifier).sendRequest(phone);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success ? '친구 요청을 보냈어요!' : '요청에 실패했어요'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('요청', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showFriendDetail(BuildContext context, Friend friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryBlue,
              child: Text(
                friend.name.isNotEmpty ? friend.name[0] : '?',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              friend.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (friend.phone != null)
              Text(
                friend.phone!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.grayMedium,
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem('약속', '${friend.eventCount}'),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.grayLight,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                ),
                _buildStatItem(
                  '친구 기간',
                  '${DateTime.now().difference(friend.createdAt).inDays}일',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _createEventWithFriend(friend);
                },
                icon: const Icon(Icons.add),
                label: const Text('약속 만들기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grayMedium,
          ),
        ),
      ],
    );
  }

  void _createEventWithFriend(Friend friend) {
    // TODO: 이벤트 생성 페이지로 이동 (친구 미리 선택)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${friend.name}님과 약속 만들기')),
    );
  }

  void _showFriendOptions(BuildContext context, Friend friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('약속 만들기'),
              onTap: () {
                Navigator.pop(context);
                _createEventWithFriend(friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.warningYellow),
              title: const Text(
                '차단하기',
                style: TextStyle(color: AppColors.warningYellow),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: 차단
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: AppColors.errorRed),
              title: const Text(
                '친구 삭제',
                style: TextStyle(color: AppColors.errorRed),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveFriend(friend);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveFriend(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${friend.name}님을 친구에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final success = await ref
                  .read(friendsProvider.notifier)
                  .removeFriend(friend.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '친구가 삭제되었어요' : '삭제에 실패했어요'),
                  ),
                );
              }
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(Friend friend) async {
    final success =
        await ref.read(friendsProvider.notifier).acceptRequest(friend.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '${friend.name}님과 친구가 되었어요!'
              : '요청 수락에 실패했어요'),
        ),
      );
    }
  }

  Future<void> _rejectRequest(Friend friend) async {
    final success =
        await ref.read(friendsProvider.notifier).rejectRequest(friend.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '요청을 거절했어요' : '거절에 실패했어요'),
        ),
      );
    }
  }
}
