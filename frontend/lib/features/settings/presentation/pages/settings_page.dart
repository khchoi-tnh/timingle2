import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/settings_tile.dart';

/// 설정 페이지
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 섹션
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0] : '?',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '사용자',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grayMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.grayMedium,
                    ),
                    onPressed: () {
                      // TODO: 프로필 편집
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('프로필 편집 기능 준비 중')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 알림 설정
            _buildSectionHeader('알림'),
            Container(
              color: AppColors.white,
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: '알림 설정',
                    onTap: () {
                      // TODO: 알림 설정 페이지
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('알림 설정 기능 준비 중')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.do_not_disturb_on_outlined,
                    title: '방해 금지 모드',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // TODO: 방해 금지 모드 토글
                      },
                      activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 앱 설정
            _buildSectionHeader('앱 설정'),
            Container(
              color: AppColors.white,
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.language_outlined,
                    title: '언어',
                    subtitle: '한국어',
                    onTap: () {
                      // TODO: 언어 설정
                      _showLanguageDialog(context);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: '다크 모드',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // TODO: 다크 모드 토글
                      },
                      activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.primaryBlue,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.access_time_outlined,
                    title: '시간대',
                    subtitle: 'Asia/Seoul (UTC+9)',
                    onTap: () {
                      // TODO: 시간대 설정
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('시간대 설정 기능 준비 중')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 정보 및 지원
            _buildSectionHeader('정보 및 지원'),
            Container(
              color: AppColors.white,
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: '앱 정보',
                    subtitle: 'v1.0.0',
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.help_outline,
                    title: '도움말',
                    onTap: () {
                      // TODO: 도움말 페이지
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('도움말 기능 준비 중')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.feedback_outlined,
                    title: '피드백 보내기',
                    onTap: () {
                      // TODO: 피드백 보내기
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('피드백 기능 준비 중')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    title: '이용약관',
                    onTap: () {
                      // TODO: 이용약관
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: '개인정보 처리방침',
                    onTap: () {
                      // TODO: 개인정보 처리방침
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 계정
            _buildSectionHeader('계정'),
            Container(
              color: AppColors.white,
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.logout,
                    title: '로그아웃',
                    titleColor: AppColors.errorRed,
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.delete_outline,
                    title: '계정 삭제',
                    titleColor: AppColors.errorRed,
                    onTap: () => _showDeleteAccountDialog(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.grayMedium,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('언어 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check, color: AppColors.primaryBlue),
              title: const Text('한국어'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('English'),
              onTap: () {
                // TODO: 언어 변경
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'timingle',
      applicationVersion: 'v1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.schedule,
          color: AppColors.white,
          size: 28,
        ),
      ),
      applicationLegalese: '© 2025 timingle. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          '약속이 대화가 되는 앱',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grayDark,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text(
          '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다.\n정말 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 계정 삭제 API 호출
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계정 삭제 기능 준비 중')),
              );
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
}
