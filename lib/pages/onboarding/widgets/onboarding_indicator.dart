import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class OnboardingIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const OnboardingIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.oceanBlue : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
