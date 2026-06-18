import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/pages/home/pages/admin/admin_home_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/customer_home_page.dart';
import 'package:ocean_rent/pages/login/login_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/widgets/build_label_text_fields.dart';
import 'package:ocean_rent/widgets/custom_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  DateTime? _selectedBirthDate;
  String _selectedLicenseType = NauticalLicenseStatus.none;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _selectBirthDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final initialDate =
        _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthDate = pickedDate;
        _birthDateController.text = _formatDate(pickedDate);
      });
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    ref.read(authNotifierProvider).clearError();

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validaciones
    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos.')),
      );
      return;
    }

    if (_selectedBirthDate == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha de nacimiento.')),
      );
      return;
    }

    if (!email.contains('@')) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Introduce un correo válido.')),
      );
      return;
    }

    if (password.length < 6) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres.'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    final success = await ref
        .read(authNotifierProvider)
        .registerWithEmailAndPassword(
          email: email,
          password: password,
          name: name,
          surname: surname,
          birthDate: _selectedBirthDate!,
          nauticalLicenseType: _selectedLicenseType,
        );

    if (!mounted) return;

    if (success) {
      _navigateByRole();
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(error ?? 'No se pudo completar el registro.')),
      );
    }
  }

  Future<void> _registerWithGoogle() async {
    FocusScope.of(context).unfocus();
    ref.read(authNotifierProvider).clearError();

    final success = await ref.read(authNotifierProvider).signInWithGoogle();

    if (!mounted) return;

    if (success) {
      _navigateByRole();
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'No se pudo completar el registro con Google.',
          ),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ocean Rent'),
        actions: [
          const Icon(Icons.directions_boat_outlined),
          const SizedBox(width: AppTheme.spacing20),
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
                  const SizedBox(height: AppTheme.spacing18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacing24,
                      AppTheme.spacing28,
                      AppTheme.spacing24,
                      AppTheme.spacing24,
                    ),
                    decoration: AppTheme.simpleCardDecoration(
                      color: AppTheme.background,
                      radius: AppTheme.radiusMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Registro',
                          textAlign: TextAlign.center,
                          style: AppTheme.headlineMedium.copyWith(
                            color: AppTheme.black,
                            fontSize: AppTheme.responsiveFontSize(
                              context,
                              AppTheme.fontSize20,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing28),
                        buildLabelTextFields(context, 'Nombre'),
                        const SizedBox(height: AppTheme.spacing8),
                        CustomTextField(
                          controller: _nameController,
                          hintText: '',
                          obscureText: false,
                        ),
                        const SizedBox(height: AppTheme.spacing22),
                        buildLabelTextFields(context, 'Apellidos'),
                        const SizedBox(height: AppTheme.spacing8),
                        CustomTextField(
                          controller: _surnameController,
                          hintText: '',
                          obscureText: false,
                        ),
                        const SizedBox(height: AppTheme.spacing22),
                        buildLabelTextFields(context, 'Fecha de nacimiento'),
                        const SizedBox(height: AppTheme.spacing8),
                        GestureDetector(
                          onTap: _selectBirthDate,
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: _birthDateController,
                              hintText: 'dd/mm/aaaa',
                              obscureText: false,
                              suffixIcon: IconButton(
                                onPressed: _selectBirthDate,
                                icon: const Icon(
                                  Icons.calendar_month_outlined,
                                  color: AppTheme.deepNavy,
                                  size: AppTheme.iconSizeLarge,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacing22),

                        buildLabelTextFields(context, 'Titulación náutica'),
                        const SizedBox(height: AppTheme.spacing8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLicenseType,
                          isExpanded: true,
                          decoration: AppTheme.inputDecoration(
                            labelText: 'Titulación',
                            icon: Icons.anchor_outlined,
                          ),
                          style: AppTheme.fieldTextStyle,
                          dropdownColor: AppTheme.white,
                          borderRadius: AppTheme.borderRadiusInput,
                          items: const [
                            DropdownMenuItem(
                              value: NauticalLicenseStatus.none,
                              child: Text('Sin titulacion'),
                            ),
                            DropdownMenuItem(value: 'pnb', child: Text('PNB')),
                            DropdownMenuItem(value: 'per', child: Text('PER')),
                          ],
                          onChanged: authState.isLoading
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedLicenseType = value;
                                  });
                                },
                        ),
                        if (_selectedLicenseType !=
                            NauticalLicenseStatus.none) ...[
                          const SizedBox(height: AppTheme.spacing10),
                          Container(
                            padding: AppTheme.infoBannerPadding,
                            decoration: AppTheme.infoBannerDecoration(
                              AppTheme.sunsetGold,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.sunsetGold,
                                  size: AppTheme.iconSizeMedium,
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Expanded(
                                  child: Text(
                                    'Tras registrarte, sube el documento desde tu perfil para que el admin pueda validarlo.',
                                    style: AppTheme.infoBannerTextStyle(
                                      AppTheme.sunsetGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacing22),
                        buildLabelTextFields(context, 'Correo electrónico'),
                        const SizedBox(height: AppTheme.spacing8),
                        CustomTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: '',
                          obscureText: false,
                        ),
                        const SizedBox(height: AppTheme.spacing22),
                        buildLabelTextFields(context, 'Contraseña'),
                        const SizedBox(height: AppTheme.spacing8),
                        CustomTextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          hintText: '',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.deepNavy,
                              size: AppTheme.iconSizeLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing22),
                        buildLabelTextFields(context, 'Confirmar contraseña'),
                        const SizedBox(height: AppTheme.spacing8),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          hintText: '',
                          onSubmitted: (_) => _register(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () =>
                                  _showConfirmPassword = !_showConfirmPassword,
                            ),
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.deepNavy,
                              size: AppTheme.iconSizeLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing30),
                        SizedBox(
                          height: AppTheme.authButtonHeight,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _register,
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
                                    'Registrarse',
                                    style: AppTheme.buttonTextStyle.copyWith(
                                      color: AppTheme.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacing18),

                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: AppTheme.dividerStrong,
                                thickness: AppTheme.borderWidthThin,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing10,
                              ),
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
                                : _registerWithGoogle,
                            style: AppTheme.socialOutlinedButtonStyle,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleLogo(),
                                const SizedBox(width: AppTheme.spacing10),
                                Text(
                                  'Registrarse con Google',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: AppTheme.fontSize14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacing16),
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                    (_) => false,
                                  );
                                },
                          child: Text(
                            '¿Ya tienes cuenta? Inicia sesión',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.oceanBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: AppTheme.fontSize14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: AppTheme.spacing16),
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
