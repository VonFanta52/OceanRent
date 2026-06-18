// Archivo central del diseño de OceanRent.
// Aquí se agrupan colores, tipografías, tamaños, espaciados, radios,
// decoraciones, botones y estilos reutilizables de la aplicación.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class AppTheme {
  AppTheme._();

  // 1. Colores oficiales del proyecto

  static const Color deepNavy = Color(0xFF0A2342);
  static const Color oceanBlue = Color(0xFF2CA58D);
  static const Color pearlWhite = Color(0xFFF4F7F5);
  static const Color sunsetGold = Color(0xFFE8A020);
  static const Color alertRed = Color(0xFFE53935);

  // 2. Colores semánticos reutilizables

  static const Color navy = deepNavy;
  static const Color teal = oceanBlue;
  static const Color tealDark = Color(0xFF2A9D8C);

  static const Color background = pearlWhite;
  static const Color backgroundDim = Color(0xFFE8E8E8);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF7B8194);
  static const Color textMuted = Color(0xFF4B5563);

  static const Color divider = Color(0xFFE4E7EF);
  static const Color dividerStrong = Color(0xFFD1D5DB);
  static const Color fieldBorder = deepNavy;

  static const Color success = Color(0xFF00C07F);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = alertRed;

  // Colores neutros para evitar Colors.* repartido por pantallas.
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color grey = Colors.grey;
  static const Color transparent = Colors.transparent;

  // Colores usados en ilustraciones y elementos gráficos.
  static const Color boatPurple = Color(0xFF514964);
  static const Color boatDark = Color(0xFF28334F);
  static const Color windowBlue = Color(0xFF1D6F9F);

  // 3. Opacidades globales

  static const double alphaVerySoft = 0.04;
  static const double alphaUltraSoft = 0.05;
  static const double alphaSoft = 0.08;
  static const double alphaLight = 0.10;
  static const double alphaMedium = 0.12;
  static const double alphaChip = 0.15;
  static const double alphaShadow = 0.18;
  static const double alphaHeroShadow = 0.18;
  static const double alphaOverlayLight = 0.20;
  static const double alphaBorder = 0.25;
  static const double alphaBorderStrong = 0.30;
  static const double alphaGlow = 0.35;
  static const double alphaOverlay = 0.40;
  static const double alphaMuted = 0.45;
  static const double alphaDisabled = 0.50;
  static const double alphaTextSecondary = 0.55;
  static const double alphaTextSoft = 0.72;
  static const double alphaTextOnDark = 0.75;
  static const double alphaTextMuted = 0.78;

  // 4. Espaciados base

  static const double spacing2 = 2;
  static const double spacing3 = 3;
  static const double spacing4 = 4;
  static const double spacing5 = 5;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing14 = 14;
  static const double spacing16 = 16;
  static const double spacing18 = 18;
  static const double spacing20 = 20;
  static const double spacing22 = 22;
  static const double spacing24 = 24;
  static const double spacing26 = 26;
  static const double spacing28 = 28;
  static const double spacing30 = 30;
  static const double spacing32 = 32;
  static const double spacing34 = 34;
  static const double spacing36 = 36;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing96 = 96;

  // 5. Paddings y margins reutilizables

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spacing24,
    vertical: spacing20,
  );

  static const EdgeInsets formPagePadding = EdgeInsets.symmetric(
    horizontal: spacing20,
    vertical: spacing24,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(spacing20);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(spacing16);
  static const EdgeInsets sectionPadding = EdgeInsets.all(spacing18);
  static const EdgeInsets listPadding = EdgeInsets.all(spacing16);

  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: spacing16,
    vertical: spacing14,
  );

  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: spacing12,
    vertical: spacing10,
  );

  static const EdgeInsets filterHeaderPadding = EdgeInsets.fromLTRB(
    spacing16,
    spacing8,
    spacing16,
    0,
  );

  static const EdgeInsets cardBottomMargin = EdgeInsets.only(bottom: spacing16);

  static const EdgeInsets activeFilterChipMargin = EdgeInsets.only(
    left: spacing8,
  );

  static const EdgeInsets detailBottomButtonPadding = EdgeInsets.fromLTRB(
    spacing16,
    spacing8,
    spacing16,
    spacing16,
  );

  static const EdgeInsets profileBadgePadding = EdgeInsets.symmetric(
    horizontal: spacing10,
    vertical: spacing3,
  );

  static const EdgeInsets licenseStatusBadgePadding = EdgeInsets.symmetric(
    horizontal: spacing12,
    vertical: spacing5,
  );

  static const EdgeInsets documentUploadPadding = EdgeInsets.symmetric(
    vertical: spacing20,
    horizontal: spacing16,
  );

  static const EdgeInsets browseBadgePadding = EdgeInsets.symmetric(
    horizontal: spacing8,
    vertical: spacing3,
  );

  static const EdgeInsets infoBannerPadding = EdgeInsets.symmetric(
    horizontal: spacing14,
    vertical: spacing10,
  );

  static const EdgeInsets generatedUrlMargin = EdgeInsets.only(
    bottom: spacing8,
  );

  static const EdgeInsets adminWidgetCardPadding = EdgeInsets.all(spacing14);

  static const EdgeInsets adminDashboardPadding = EdgeInsets.fromLTRB(
    spacing16,
    spacing18,
    spacing16,
    spacing96,
  );

  static const EdgeInsets adminHeaderPadding = EdgeInsets.all(spacing18);

  static const EdgeInsets adminActionIconPadding = EdgeInsets.only(
    right: spacing16,
  );
  static const EdgeInsets dialogActionsPadding = EdgeInsets.only(
    left: spacing16,
    right: spacing16,
    bottom: spacing12,
  );

  static const EdgeInsets authFormCardPadding = EdgeInsets.fromLTRB(
    spacing24,
    spacing28,
    spacing24,
    spacing24,
  );

  static const EdgeInsets dividerLabelPadding = EdgeInsets.symmetric(
    horizontal: spacing10,
  );

  // 6. Radios reutilizables

  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 10;
  static const double radiusInput = 12;
  static const double radiusButton = 14;
  static const double radiusLg = 16;
  static const double radiusCard = 8;
  static const double radiusBadge = 20;
  static const double radiusHero = 22;
  static const double radiusPill = 999;

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );

  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  static const BorderRadius borderRadiusInput = BorderRadius.all(
    Radius.circular(radiusInput),
  );

  static const BorderRadius borderRadiusButton = BorderRadius.all(
    Radius.circular(radiusButton),
  );

  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  static const BorderRadius borderRadiusCard = BorderRadius.all(
    Radius.circular(radiusCard),
  );

  static const BorderRadius borderRadiusCardTop = BorderRadius.vertical(
    top: Radius.circular(radiusCard),
  );

  static const BorderRadius borderRadiusBadge = BorderRadius.all(
    Radius.circular(radiusBadge),
  );

  static const BorderRadius borderRadiusHero = BorderRadius.all(
    Radius.circular(radiusHero),
  );

  static const BorderRadius borderRadiusPill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  // 7. Tamaños de texto

  static const double fontSize11 = 11;
  static const double fontSize12 = 12;
  static const double fontSize13 = 13;
  static const double fontSize14 = 14;
  static const double fontSize15 = 15;
  static const double fontSize16 = 16;
  static const double fontSize18 = 18;
  static const double fontSize20 = 20;
  static const double fontSize22 = 22;
  static const double fontSize24 = 24;
  static const double fontSize26 = 26;
  static const double fontSize30 = 30;

  // 8. Tamaños de iconos y componentes

  static const double iconSizeMini = 12;
  static const double iconSizeSmall = 14;
  static const double iconSizeMd = 16;
  static const double iconSizeMedium = 18;
  static const double iconSizeLg = 20;
  static const double iconSizeXl = 22;
  static const double iconSizeLarge = 24;
  static const double iconSize2xl = 26;
  static const double iconSize3xl = 30;

  static const double emptyStateIconSize = 42;
  static const double placeholderIconSize = 48;
  static const double imagePickerIconSize = 52;
  static const double detailPlaceholderIconSize = 56;

  static const double buttonHeight = 52;
  static const double authButtonHeight = 46;
  static const double socialButtonHeight = 48;
  static const double compactButtonHeight = 48;
  static const double onboardingButtonHeight = 72;

  static const double avatarSize = 90;
  static const double avatarCameraSize = 28;

  static const double loadingSize = 22;
  static const double documentUploadLoadingSize = 28;
  static const double authLogoSize = 20;

  static const double adminHeaderIconBoxSize = 54;
  static const double quickActionIconBoxSize = 42;
  static const double summaryIconBoxSize = 44;

  static const double onboardingIndicatorWidth = 28;
  static const double onboardingIndicatorHeight = 8;
  static const double onboardingDotSize = 9;
  static const double onboardingIllustrationWidth = 260;
  static const double onboardingIllustrationHeight = 140;

  static const double imageHeight = 180;
  static const double customerBoatImageHeight = 170;
  static const double formImagePreviewHeight = 190;
  static const double detailImageHeight = 260;

  static const int imageGridCrossAxisCount = 3;

  // 9. Bordes, sombras y medidas auxiliares

  static const double borderWidthThin = 1;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthStrong = 1.8;
  static const double borderWidthInput = 1.9;

  static const double progressStrokeWidth = 2.5;

  static const double shadowBlurXs = 4;
  static const double shadowBlurSm = 10;
  static const double shadowBlurMd = 12;
  static const double shadowBlurLg = 16;
  static const double shadowBlurXl = 20;

  static const double lineHeightTight = 1.2;
  static const double lineHeightSmall = 1.3;
  static const double lineHeightRegular = 1.35;
  static const double lineHeightInfo = 1.4;
  static const double lineHeightLarge = 1.45;

  static const double letterSpacingXs = 0.2;
  static const double letterSpacingMd = 0.8;

  static const double adminSummaryAspectRatio = 1.25;

  // 10. Duraciones

  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration fadeDuration = Duration(milliseconds: 600);

  // 11. Helpers reutilizables para adaptabilidad y responsividad

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  static double responsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 360) return baseSize - 1;
    if (width >= 600) return baseSize + 1;

    return baseSize;
  }

  static double responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 360) return spacing16;
    if (width >= 600) return spacing32;

    return spacing24;
  }

  static EdgeInsets responsiveScreenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveHorizontalPadding(context),
      vertical: spacing20,
    );
  }

  static EdgeInsets responsiveHorizontalScreenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveHorizontalPadding(context),
    );
  }

  static double maxContentWidth(BuildContext context) {
    return isTablet(context) ? 560 : double.infinity;
  }

  // 12. ThemeData principal

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: deepNavy,
        secondary: oceanBlue,
        error: alertRed,
        surface: pearlWhite,
        onPrimary: white,
        onSecondary: white,
        onError: white,
        onSurface: deepNavy,
      ),
      textTheme: TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: deepNavy,
        foregroundColor: white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: appBarTitleStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: inputContentPadding,
        border: outlineBorder(fieldBorder),
        enabledBorder: outlineBorder(fieldBorder),
        focusedBorder: outlineBorder(oceanBlue, width: borderWidthMedium),
        errorBorder: outlineBorder(error),
        focusedErrorBorder: outlineBorder(error, width: borderWidthMedium),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: borderWidthThin,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: deepNavy,
        contentTextStyle: bodyMedium.copyWith(color: white),
        shape: const RoundedRectangleBorder(borderRadius: borderRadiusInput),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: oceanBlue.withValues(alpha: alphaLight),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return labelSmall.copyWith(
              color: deepNavy,
              fontWeight: FontWeight.w700,
            );
          }

          return labelSmall;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: oceanBlue);
          }

          return const IconThemeData(color: textSecondary);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: oceanBlue,
        foregroundColor: white,
      ),
    );
  }

  // 13. TextStyles globales

  static TextStyle get headlineLarge => GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: fontSize24,
    color: deepNavy,
  );

  static TextStyle get headlineMedium => GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: fontSize18,
    color: deepNavy,
  );

  static TextStyle get headlineSmall => GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: fontSize14,
    color: deepNavy,
  );

  static TextStyle get titleLarge => GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: fontSize24,
    color: deepNavy,
  );

  static TextStyle get titleMedium => GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: fontSize18,
    color: deepNavy,
  );

  static TextStyle get titleSmall => GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: fontSize14,
    color: deepNavy,
  );

  static TextStyle get bodyLarge =>
      GoogleFonts.openSans(fontSize: fontSize18, color: deepNavy);

  static TextStyle get bodyMedium =>
      GoogleFonts.openSans(fontSize: fontSize16, color: textSecondary);

  static TextStyle get bodySmall =>
      GoogleFonts.openSans(fontSize: fontSize14, color: textSecondary);

  static TextStyle get labelLarge => GoogleFonts.montserrat(
    fontSize: fontSize15,
    fontWeight: FontWeight.w700,
    color: deepNavy,
  );

  static TextStyle get labelMedium => GoogleFonts.openSans(
    fontSize: fontSize13,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static TextStyle get labelSmall => GoogleFonts.openSans(
    fontSize: fontSize12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static TextStyle get appBarTitleStyle => GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: fontSize18,
    color: white,
  );

  static TextStyle get sectionLabelStyle => const TextStyle(
    fontSize: fontSize13,
    fontWeight: FontWeight.w700,
    color: textSecondary,
    letterSpacing: letterSpacingMd,
  );

  static TextStyle get cardTitleStyle => const TextStyle(
    fontSize: fontSize20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get fieldTextStyle => const TextStyle(
    fontSize: fontSize15,
    color: textPrimary,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get readOnlyFieldTextStyle =>
      fieldTextStyle.copyWith(color: textSecondary);

  static TextStyle get fieldLabelStyle =>
      const TextStyle(color: textSecondary, fontSize: fontSize13);

  static TextStyle get badgeTextStyle => const TextStyle(
    fontSize: fontSize12,
    color: teal,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get buttonTextStyle => const TextStyle(
    fontSize: fontSize15,
    fontWeight: FontWeight.w700,
    letterSpacing: letterSpacingXs,
  );

  static TextStyle get helperTextStyle =>
      const TextStyle(fontSize: fontSize12, color: textSecondary);

  static TextStyle get onboardingTitleStyle => GoogleFonts.montserrat(
    color: pearlWhite,
    fontSize: fontSize24,
    fontWeight: FontWeight.w800,
    letterSpacing: letterSpacingXs,
  );

  static TextStyle get onboardingSubtitleStyle => GoogleFonts.montserrat(
    color: pearlWhite,
    fontSize: fontSize24,
    fontWeight: FontWeight.w700,
    height: lineHeightTight,
  );

  static TextStyle get onboardingPrimaryButtonTextStyle =>
      GoogleFonts.montserrat(
        fontSize: fontSize22,
        fontWeight: FontWeight.w800,
        letterSpacing: letterSpacingXs,
      );

  static TextStyle get onboardingSecondaryButtonTextStyle =>
      GoogleFonts.montserrat(
        fontSize: fontSize20,
        fontWeight: FontWeight.w800,
        letterSpacing: letterSpacingXs,
      );

  static TextStyle get onboardingLinkTextStyle => GoogleFonts.montserrat(
    color: pearlWhite,
    fontSize: fontSize16,
    fontWeight: FontWeight.w800,
    letterSpacing: letterSpacingXs,
  );

  static TextStyle infoBannerTextStyle(Color color) {
    return TextStyle(
      fontSize: fontSize12,
      color: color,
      fontWeight: FontWeight.w500,
      height: lineHeightInfo,
    );
  }

  // 14. Sombras

  static List<BoxShadow> cardShadow({double alpha = alphaUltraSoft}) {
    return [
      BoxShadow(
        color: black.withValues(alpha: alpha),
        blurRadius: shadowBlurXl,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> softShadow({double alpha = alphaSoft}) {
    return [
      BoxShadow(
        color: black.withValues(alpha: alpha),
        blurRadius: shadowBlurMd,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // 15. Decoraciones reutilizables

  static BoxDecoration get bottomNavigationDecoration {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: black.withValues(alpha: alphaOverlayLight),
          blurRadius: shadowBlurSm,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({
    Color color = surface,
    double radius = radiusCard,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: boxShadow ?? cardShadow(),
    );
  }

  static BoxDecoration simpleCardDecoration({
    Color color = surface,
    double radius = radiusCard,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration badgeDecoration({
    required Color color,
    double alpha = alphaMedium,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: alpha),
      borderRadius: borderRadiusPill,
      border: Border.all(color: color.withValues(alpha: alphaBorder)),
    );
  }

  static BoxDecoration avatarDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [teal, tealDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: teal.withValues(alpha: alphaGlow),
          blurRadius: shadowBlurXl,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration profileAvatarDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [oceanBlue, deepNavy],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: oceanBlue.withValues(alpha: alphaGlow),
          blurRadius: shadowBlurXl,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration profileCameraDecoration() {
    return BoxDecoration(
      color: white,
      shape: BoxShape.circle,
      border: Border.all(
        color: deepNavy.withValues(alpha: alphaMedium),
        width: borderWidthMedium,
      ),
    );
  }

  static BoxDecoration uploadBoxDecoration({required bool hasFile}) {
    return BoxDecoration(
      color: hasFile ? teal.withValues(alpha: alphaVerySoft) : surface,
      borderRadius: borderRadiusInput,
      border: Border.all(
        color: hasFile ? teal.withValues(alpha: alphaOverlay) : fieldBorder,
        width: borderWidthMedium,
      ),
    );
  }

  static BoxDecoration infoBannerDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: alphaSoft),
      borderRadius: borderRadiusMd,
      border: Border.all(color: color.withValues(alpha: alphaBorder)),
    );
  }

  static BoxDecoration adminCardDecoration() {
    return cardDecoration(
      color: surface,
      border: Border.all(color: deepNavy.withValues(alpha: alphaSoft)),
      boxShadow: softShadow(alpha: alphaUltraSoft),
    );
  }

  static BoxDecoration adminIconBoxDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: alphaMedium),
      borderRadius: borderRadiusButton,
    );
  }

  static BoxDecoration adminHeaderDecoration() {
    return BoxDecoration(
      color: deepNavy,
      borderRadius: borderRadiusHero,
      boxShadow: [
        BoxShadow(
          color: deepNavy.withValues(alpha: alphaHeroShadow),
          blurRadius: shadowBlurLg,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // 16. Inputs y bordes

  static OutlineInputBorder outlineBorder(
    Color color, {
    double width = borderWidthThin,
  }) {
    return OutlineInputBorder(
      borderRadius: borderRadiusInput,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static InputDecoration inputDecoration({
    required String labelText,
    IconData? icon,
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: fieldLabelStyle,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: iconSizeMedium, color: textSecondary),
      filled: true,
      fillColor: readOnly ? backgroundDim : surface,
      contentPadding: inputContentPadding,
      border: outlineBorder(fieldBorder),
      enabledBorder: outlineBorder(fieldBorder),
      focusedBorder: outlineBorder(teal, width: borderWidthMedium),
      errorBorder: outlineBorder(error),
      focusedErrorBorder: outlineBorder(error, width: borderWidthMedium),
    );
  }

  // 17. Estilos de calendario

  static HeaderStyle get calendarHeaderStyle {
    return HeaderStyle(
      formatButtonVisible: false,
      titleCentered: true,
      titleTextStyle: titleLarge.copyWith(color: deepNavy),
      leftChevronIcon: const Icon(
        Icons.chevron_left,
        color: deepNavy,
        size: iconSizeLarge,
      ),
      rightChevronIcon: const Icon(
        Icons.chevron_right,
        color: deepNavy,
        size: iconSizeLarge,
      ),
    );
  }

  static DaysOfWeekStyle get calendarDaysOfWeekStyle {
    return DaysOfWeekStyle(
      weekdayStyle: bodySmall.copyWith(
        color: deepNavy,
        fontWeight: FontWeight.w700,
      ),
      weekendStyle: bodySmall.copyWith(
        color: oceanBlue,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static CalendarStyle get calendarStyle {
    return CalendarStyle(
      todayDecoration: BoxDecoration(
        color: oceanBlue.withValues(alpha: alphaOverlay),
        shape: BoxShape.circle,
      ),
      todayTextStyle: const TextStyle(color: deepNavy),
      selectedDecoration: const BoxDecoration(
        color: deepNavy,
        shape: BoxShape.circle,
      ),
      selectedTextStyle: const TextStyle(color: white),
      disabledDecoration: const BoxDecoration(
        color: dividerStrong,
        shape: BoxShape.circle,
      ),
      disabledTextStyle: TextStyle(
        color: textSecondary.withValues(alpha: alphaTextSecondary),
      ),
      defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
      defaultTextStyle: const TextStyle(color: deepNavy),
      weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
      weekendTextStyle: const TextStyle(color: oceanBlue),
      outsideDaysVisible: false,
    );
  }

  // 18. Estilos de botones

  static ButtonStyle get primaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: deepNavy,
      foregroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusInput),
    );
  }

  static ButtonStyle get accentButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: oceanBlue,
      foregroundColor: white,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusButton),
    );
  }

  static ButtonStyle get destructiveButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: alertRed,
      foregroundColor: white,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusButton),
    );
  }

  static ButtonStyle get outlinedButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: deepNavy,
      side: BorderSide(color: deepNavy.withValues(alpha: alphaBorder)),
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusButton),
    );
  }

  static ButtonStyle get socialOutlinedButtonStyle {
    return OutlinedButton.styleFrom(
      backgroundColor: white,
      foregroundColor: deepNavy,
      side: const BorderSide(color: dividerStrong),
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
      padding: const EdgeInsets.symmetric(horizontal: spacing14),
    );
  }

  static ButtonStyle get textButtonStyle {
    return TextButton.styleFrom(foregroundColor: oceanBlue);
  }

  static ButtonStyle get compactTextButtonStyle {
    return TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static ButtonStyle get fullWidthPrimaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: deepNavy,
      foregroundColor: pearlWhite,
      minimumSize: const Size.fromHeight(buttonHeight),
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusButton),
    );
  }

  static ButtonStyle onboardingButtonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusSm),
    );
  }
}
