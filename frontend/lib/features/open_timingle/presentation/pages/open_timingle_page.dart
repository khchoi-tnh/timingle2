import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/open_timingle_provider.dart';
import '../widgets/open_slot_card.dart';

/// Open Timingle 페이지 - 오픈 예약 마켓플레이스
class OpenTiminglePage extends ConsumerStatefulWidget {
  const OpenTiminglePage({super.key});

  @override
  ConsumerState<OpenTiminglePage> createState() => _OpenTiminglePageState();
}

class _OpenTiminglePageState extends ConsumerState<OpenTiminglePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(openTimingleProvider.notifier).loadSlots();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openTimingleProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(
              Icons.event_available,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Open',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.grayDark),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                hintStyle: const TextStyle(color: AppColors.grayMedium),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.grayMedium),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear, color: AppColors.grayMedium),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(openTimingleProvider.notifier)
                              .setSearchQuery('');
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
                ref.read(openTimingleProvider.notifier).setSearchQuery(value);
              },
            ),
          ),

          // 카테고리 칩
          Container(
            color: AppColors.white,
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = state.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(openTimingleProvider.notifier)
                          .selectCategory(category);
                    },
                    backgroundColor: AppColors.white,
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    checkmarkColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.grayDark,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.grayLight,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 슬롯 목록
          Expanded(
            child: _buildSlotList(state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 내 슬롯 생성 페이지로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('슬롯 생성 기능 준비 중')),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          '내 시간 공개',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotList(OpenTimingleState state) {
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: AppColors.grayDark),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(openTimingleProvider.notifier).loadSlots();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final filteredSlots = state.filteredSlots;

    if (filteredSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: AppColors.grayMedium.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty || state.selectedCategory != '전체'
                  ? '조건에 맞는 슬롯이 없어요'
                  : '공개된 슬롯이 없어요',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.grayDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '다른 조건으로 검색해보세요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grayMedium,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(openTimingleProvider.notifier).loadSlots(),
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: filteredSlots.length,
        itemBuilder: (context, index) {
          final slot = filteredSlots[index];
          return OpenSlotCard(
            slot: slot,
            onTap: () {
              _showSlotDetailBottomSheet(context, slot);
            },
            onBook: () {
              _showBookingConfirmDialog(context, slot);
            },
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '필터',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '정렬',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterOption('최신순', true),
                _buildFilterOption('가격 낮은순', false),
                _buildFilterOption('가격 높은순', false),
                _buildFilterOption('시간순', false),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '가격대',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterOption('전체', true),
                _buildFilterOption('~3만원', false),
                _buildFilterOption('3~5만원', false),
                _buildFilterOption('5만원~', false),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '적용',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {},
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryBlue : AppColors.grayDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : AppColors.grayLight,
        ),
      ),
    );
  }

  void _showSlotDetailBottomSheet(BuildContext context, dynamic slot) {
    // TODO: 상세 정보 바텀시트
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${slot.title} 상세 정보')),
    );
  }

  void _showBookingConfirmDialog(BuildContext context, dynamic slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 확인'),
        content: Text('${slot.title}을(를) 예약하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(openTimingleProvider.notifier)
                  .bookSlot(slot.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '예약이 완료되었습니다!' : '예약에 실패했습니다'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text(
              '예약하기',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
