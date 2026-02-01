import 'package:flutter/material.dart';
import '../../../../design_system/molecules/ff_auth_header.dart';
import '../../../../design_system/tokens/ff_colors.dart';
import '../../../../design_system/tokens/ff_spacing.dart';
import '../../../../design_system/tokens/ff_radius.dart';
import '../../../../design_system/tokens/ff_shadows.dart';
import '../../../../design_system/tokens/ff_gradients.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: FFColors.background,
      body: SafeArea(
        child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: FFSpacing.lg,
        vertical: FFSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FFAuthHeader(
            title: '로그인',
            subtitle: '계정으로 로그인하여\n의료 시스템에 접속하세요',
            icon: Icons.local_hospital_rounded,
            showIcon: true,
          ),
          SizedBox(height: FFSpacing.huge),
          LoginForm(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left Side - Branding
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: FFGradients.primary,
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(FFSpacing.huge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: FFColors.textInverse.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(FFRadius.xxl),
                            ),
                            child: Icon(
                              Icons.local_hospital_rounded,
                              size: 70,
                              color: FFColors.textInverse,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: FFSpacing.xxxl),
                    // Title
                    Text(
                      'Healthcare Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: FFColors.textInverse,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: FFSpacing.lg),
                    // Subtitle
                    Text(
                      '1000+ 병원의 의료 데이터를\n안전하게 관리하는 플랫폼',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: FFColors.textInverse.withOpacity(0.8),
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: FFSpacing.xxxl),
                    // Features
                    Column(
                      children: [
                        _buildFeatureItem('🔒 ISMS-P 인증', '의료정보 보안 표준'),
                        SizedBox(height: FFSpacing.lg),
                        _buildFeatureItem('⚡ 실시간 동기화', '모든 데이터 실시간 동기'),
                        SizedBox(height: FFSpacing.lg),
                        _buildFeatureItem('🌐 글로벌 표준', 'HL7 FHIR 준수'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right Side - Login Form
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: FFColors.backgroundLight,
              boxShadow: [
                BoxShadow(
                  color: FFColors.shadow,
                  blurRadius: 20,
                  offset: Offset(-4, 0),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(FFSpacing.huge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FFAuthHeader(
                    title: '로그인',
                    subtitle: '의료 시스템에 접속하세요',
                    icon: Icons.lock_outline,
                    showIcon: true,
                  ),
                  SizedBox(height: FFSpacing.xxxl),
                  LoginForm(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: FFColors.textInverse.withOpacity(0.1),
            borderRadius: BorderRadius.circular(FFRadius.lg),
          ),
          child: Center(
            child: Text(
              title.split(' ')[0],
              style: TextStyle(fontSize: 24),
            ),
          ),
        ),
        SizedBox(width: FFSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.split(' ').skip(1).join(' '),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: FFColors.textInverse,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: FFColors.textInverse.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
