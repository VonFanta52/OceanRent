import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/pages/home/pages/admin/admin_home_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/customer_home_page.dart';
import 'package:ocean_rent/pages/login/pages/register_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/widgets/build_label_text_fields.dart';
import 'package:ocean_rent/widgets/custom_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();

  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  void _navigateByRole() {
    final user = ref.read(authNotifierProvider).currentUser;
    if (user == null) return;

    final destination = switch (user.role) {
      UserRole.admin => const AdminHomePage(),
      UserRole.customer => const CustomerHomePage(),
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    ref.read(authNotifierProvider).clearError();

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Rellena correo y contraseña.')),
      );
      return;
    }

    if (!email.contains('@')) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Introduce un correo válido.')),
      );
      return;
    }

    final success = await ref
        .read(authNotifierProvider)
        .signInWithEmailAndPassword(email: email, password: password);

    if (!mounted) return;

    if (success) {
      _navigateByRole();
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(error ?? 'No se pudo iniciar sesión.')),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();
    ref.read(authNotifierProvider).clearError();

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = await ref.read(authNotifierProvider).signInWithGoogle();

    if (!mounted) return;

    if (success) {
      _navigateByRole();
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo iniciar sesión con Google.'),
        ),
      );
    }
  }

  Future<void> _showResetPasswordDialog() async {
    FocusScope.of(context).unfocus();
    ref.read(authNotifierProvider).clearError();

    _resetEmailController.text = _emailController.text.trim();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusCard,
          ),
          title: Text('Recuperar contraseña', style: AppTheme.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Introduce tu correo y te enviaremos un enlace para restablecer la contraseña.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                    height: AppTheme.lineHeightInfo,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                TextField(
                  controller: _resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.fieldTextStyle,
                  decoration: AppTheme.inputDecoration(
                    labelText: 'Correo electrónico',
                  ).copyWith(hintText: 'ejemplo@correo.com'),
                ),
              ],
            ),
          ),
          actionsPadding: AppTheme.dialogActionsPadding,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar', style: AppTheme.labelMedium),
            ),
            ElevatedButton(
              style: AppTheme.accentButtonStyle,
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(_resetEmailController.text.trim());
              },
              child: Text(
                'Enviar',
                style: AppTheme.buttonTextStyle.copyWith(color: AppTheme.white),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || email == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Introduce un correo electrónico.')),
      );
      return;
    }

    if (!normalizedEmail.contains('@')) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Introduce un correo válido.')),
      );
      return;
    }

    final success = await ref
        .read(authNotifierProvider)
        .sendPasswordResetEmail(email: normalizedEmail);

    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    scaffoldMessenger.hideCurrentSnackBar();
    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Si el email es correcto, recibirás un correo para restablecer la contraseña.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'No se pudo enviar el correo de recuperacion.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildGoogleLogo() {
    return Image.asset(
      'assets/icons/google_logo.png',
      width: AppTheme.authLogoSize,
      height: AppTheme.authLogoSize,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Ocean Rent'),
        actions: const [
          Icon(Icons.directions_boat_outlined),
          SizedBox(width: AppTheme.spacing20),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppTheme.responsiveScreenPadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppTheme.maxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                      vertical: AppTheme.spacing20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar sesión',
                          textAlign: TextAlign.center,
                          style: AppTheme.headlineMedium.copyWith(
                            color: AppTheme.deepNavy,
                            fontSize: AppTheme.responsiveFontSize(
                              context,
                              AppTheme.fontSize20,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing28),
                        buildLabelTextFields(context, 'Correo electrónico'),
                        const SizedBox(height: AppTheme.spacing8),
                        CustomTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'usuario@correo.com',
                          obscureText: false,
                        ),
                        const SizedBox(height: AppTheme.spacing22),
                        buildLabelTextFields(context, 'Contrasena'),
                        const SizedBox(height: AppTheme.spacing8),
                        CustomTextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          hintText: '',
                          onSubmitted: (_) => _login(),
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.deepNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing18),
                        SizedBox(
                          height: AppTheme.authButtonHeight,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _login,
                            style: AppTheme.accentButtonStyle,
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: AppTheme.loadingSize,
                                    height: AppTheme.loadingSize,
                                    child: CircularProgressIndicator(
                                      strokeWidth: AppTheme.borderWidthThin * 2,
                                      color: AppTheme.white,
                                    ),
                                  )
                                : Text(
                                    'Entrar',
                                    style: AppTheme.buttonTextStyle.copyWith(
                                      color: AppTheme.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : _showResetPasswordDialog,
                            style: AppTheme.compactTextButtonStyle,
                            child: Text(
                              '¿Has olvidado tu contraseña?',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.oceanBlue,
                                fontSize: AppTheme.fontSize12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing14),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: AppTheme.dividerStrong,
                                thickness: AppTheme.borderWidthThin,
                              ),
                            ),
                            Padding(
                              padding: AppTheme.dividerLabelPadding,
                              child: Text(
                                'o',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontSize13,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: AppTheme.dividerStrong,
                                thickness: AppTheme.borderWidthThin,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing18),
                        SizedBox(
                          height: AppTheme.socialButtonHeight,
                          child: OutlinedButton(
                            onPressed: authState.isLoading
                                ? null
                                : _loginWithGoogle,
                            style: AppTheme.socialOutlinedButtonStyle,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleLogo(),
                                const SizedBox(width: AppTheme.spacing10),
                                Flexible(
                                  child: Text(
                                    'Continuar con Google',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: AppTheme.fontSize14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing18),
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                          child: Text(
                            'No tienes cuenta? Registrate',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.oceanBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: AppTheme.fontSize14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: AppTheme.spacing12),
                          Text(
                            authState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.alertRed,
                              fontSize: AppTheme.fontSize13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
