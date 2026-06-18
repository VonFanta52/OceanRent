import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/pages/onboarding/widgets/custom_card.dart';
import 'package:ocean_rent/widgets/app_navigator.dart';

class OnboardingPlacePage extends StatefulWidget {
  final Function(List<String>) onFinish;

  const OnboardingPlacePage({super.key, required this.onFinish});

  @override
  State<OnboardingPlacePage> createState() => _OnboardingPlacePageState();
}

class _OnboardingPlacePageState extends State<OnboardingPlacePage> {
  final List<String> selected = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pearlWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Text(
                '¿Dónde quieres navegar?',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 12),
              Text(
                'Selecciona tu zona preferida',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              CustomCard(
                title: 'Marbella',
                description: 'Costa del Sol, Málaga',
                isSelected: selected.contains('marbella'),
                onTap: () => setState(() {
                  selected.contains('marbella')
                      ? selected.remove('marbella')
                      : selected.add('marbella');
                }),
                imagePath: 'assets/icons/playa.svg',
              ),
              const SizedBox(height: 8),
              CustomCard(
                title: 'Málaga',
                description: 'Capital de la Costa del Sol',
                isSelected: selected.contains('malaga'),
                onTap: () => setState(() {
                  selected.contains('malaga')
                      ? selected.remove('malaga')
                      : selected.add('malaga');
                }),
                imagePath: 'assets/icons/playa.svg',
              ),
              const SizedBox(height: 8),
              CustomCard(
                title: 'Cabo Cañaveral',
                description: 'Aguas tranquilas del Mediterráneo',
                isSelected: selected.contains('cabo_canaveral'),
                onTap: () => setState(() {
                  selected.contains('cabo_canaveral')
                      ? selected.remove('cabo_canaveral')
                      : selected.add('cabo_canaveral');
                }),
                imagePath: 'assets/icons/playa.svg',
              ),
              const SizedBox(height: 224),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => widget.onFinish(selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.oceanBlue,
                    foregroundColor: AppTheme.pearlWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Explorar Barcos',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.pearlWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.deepNavy, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () => AppNavigator.goToExploreBoats(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pearlWhite,
                    foregroundColor: AppTheme.deepNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Saltar',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
