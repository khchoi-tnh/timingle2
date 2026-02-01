import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/atoms/ff_text_field.dart';
import '../../../../design_system/atoms/ff_password_field.dart';
import '../../../../design_system/atoms/ff_button.dart';
import '../../../../design_system/tokens/ff_spacing.dart';
import '../../../../design_system/tokens/ff_colors.dart';
import '../../../../design_system/tokens/ff_typography.dart';
import '../../application/auth_provider.dart';
import '../../data/auth_repository.dart';

class LoginForm extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginForm({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoginLoadingProvider);
    final error = ref.watch(loginErrorProvider);
    final user = ref.watch(currentUserProvider);

    // Show error snackbar
    ref.listen<String?>(loginErrorProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: FFColors.textInverse, size: 20),
                SizedBox(width: FFSpacing.md),
                Expanded(child: Text(next)),
              ],
            ),
            backgroundColor: FFColors.error,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(FFSpacing.lg),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    });

    // Show success snackbar
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next != null && previous == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: FFColors.textInverse, size: 20),
                SizedBox(width: FFSpacing.md),
                Expanded(child: Text('${next.name}님 환영합니다! 🎉')),
              ],
            ),
            backgroundColor: FFColors.success,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(FFSpacing.lg),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Future.delayed(Duration(seconds: 1), () {
          _emailController.clear();
          _passwordController.clear();
          setState(() => _rememberMe = false);
        });
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          FFTextField(
            label: '이메일 주소',
            hint: 'example@hospital.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(Icons.email_outlined, color: FFColors.textSecondary),
            validator: (value) {
              if (value?.isEmpty ?? true) return '이메일을 입력해주세요.';
              if (!value!.contains('@')) return '유효한 이메일 형식을 입력해주세요.';
              return null;
            },
          ),
          SizedBox(height: FFSpacing.lg),

          // Password Field
          FFPasswordField(
            label: '비밀번호',
            hint: '6자 이상의 비밀번호',
            controller: _passwordController,
            validator: (value) {
              if (value?.isEmpty ?? true) return '비밀번호를 입력해주세요.';
              if ((value?.length ?? 0) < 6) return '비밀번호는 최소 6자 이상입니다.';
              return null;
            },
          ),
          SizedBox(height: FFSpacing.lg),

          // Remember Me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                      activeColor: FFColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '로그인 유지',
                        style: FFTypography.bodySm.copyWith(
                          color: FFColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  '비밀번호 찾기',
                  style: FFTypography.bodySm.copyWith(
                    color: FFColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: FFSpacing.xxl),

          // Login Button
          FFButton(
            label: '로그인',
            onPressed: isLoading ? () {} : _handleLogin,
            isLoading: isLoading,
            height: 50,
          ),
          SizedBox(height: FFSpacing.lg),

          // Sign Up
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '계정이 없으신가요? ',
                  style: FFTypography.body.copyWith(color: FFColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    '회원가입',
                    style: FFTypography.body.copyWith(
                      color: FFColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: FFSpacing.xxl),

          // Divider with text
          Row(
            children: [
              Expanded(child: Divider(color: FFColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: FFSpacing.md),
                child: Text(
                  '또는',
                  style: FFTypography.bodySm.copyWith(color: FFColors.textTertiary),
                ),
              ),
              Expanded(child: Divider(color: FFColors.border)),
            ],
          ),
          SizedBox(height: FFSpacing.lg),

          // Social Login Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.language, size: 18),
                  label: Text('Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FFColors.textSecondary,
                    side: BorderSide(color: FFColors.border, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: FFSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: FFSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.business, size: 18),
                  label: Text('SSO'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FFColors.textSecondary,
                    side: BorderSide(color: FFColors.border, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: FFSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(loginProvider.notifier).login(
      _emailController.text,
      _passwordController.text,
    );
  }
}
