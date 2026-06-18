import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPrefService {
  static const _keySkip = 'onboarding_skip';
  Future<bool> shouldSkip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySkip) ?? false;
  }

  Future<void> markSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySkip, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySkip);
  }
}
