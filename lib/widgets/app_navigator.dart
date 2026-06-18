import 'package:flutter/material.dart';
import 'package:ocean_rent/pages/home/pages/customer/customer_home_page.dart';
import 'package:ocean_rent/pages/login/login_page.dart';

class AppNavigator {
  static void goToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  static void goToExploreBoats(
    BuildContext context, {
    List<String> categories = const [],
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerHomePage(initialCategories: categories),
      ),
    );
  }
}
