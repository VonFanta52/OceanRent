import 'package:flutter/material.dart';
import 'package:ocean_rent/pages/onboarding/pages/onboarding_category_page.dart';
import 'package:ocean_rent/pages/onboarding/pages/onboarding_place_page.dart';
import 'package:ocean_rent/pages/onboarding/pages/onboarding_primary_page.dart';
import 'package:ocean_rent/pages/onboarding/widgets/onboarding_indicator.dart';
import 'package:ocean_rent/widgets/app_navigator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  List<String> _selectedCategories = [];
  final pageController = PageController();
  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: pageController,
            children: [
              OnboardingPrimaryPage(
                onNext: () => pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
              OnboardingCategoryPage(
                onNext: (categories) {
                  setState(() => _selectedCategories = categories);
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              OnboardingPlacePage(
                onFinish: (places) {
                  AppNavigator.goToExploreBoats(
                    context,
                    categories: _selectedCategories,
                  );
                },
              ),
            ],
            onPageChanged: (index) => setState(() => currentPage = index),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: OnboardingIndicator(currentPage: currentPage, totalPages: 3),
          ),
        ],
      ),
    );
  }
}
