import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/pages/home/pages/admin/admin_home_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/customer_home_page.dart';
import 'package:ocean_rent/pages/onboarding/onboarding_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/services/onboarding/onboarding_pref_service.dart';

class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

// Esta página se encarga de decidir qué pantalla mostrar al usuario según su estado de autenticación y si ha completado el onboarding.
class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  bool _loading = true;
  bool _skipOnboarding = false;

  final _prefsService = OnboardingPrefService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final skipResult = await _prefsService.shouldSkip();
    if (!mounted) return;
    await ref.read(authNotifierProvider).checkCurrentSession();
    if (!mounted) return;
    setState(() {
      _skipOnboarding = skipResult;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    if (_loading || (auth.isLoading && auth.currentUser == null)) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.oceanBlue,
            strokeWidth: AppTheme.borderWidthMedium,
          ),
        ),
      );
    }

    if (!_skipOnboarding && auth.currentUser == null) {
      return const OnboardingPage();
    }

    if (auth.currentUser == null) return const CustomerHomePage();

    return switch (auth.currentUser!.role) {
      UserRole.admin => const AdminHomePage(),
      UserRole.customer => const CustomerHomePage(),
    };
  }
}
