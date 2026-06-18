import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/boat_list_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_bookings_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_chats_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_map_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_profile_screen.dart';
import 'package:ocean_rent/pages/onboarding/onboarding_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/widgets/app_navigator.dart';
import 'package:ocean_rent/widgets/dialog_confirmacion.dart';

class CustomerHomePage extends ConsumerStatefulWidget {
  final List<String> initialCategories;

  const CustomerHomePage({super.key, this.initialCategories = const []});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  int selectedIndex = 0;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authNotifierProvider).signOut();
    ref.invalidate(bookingsStreamProvider);
    ref.invalidate(userBookingsStreamProvider);

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
      (_) => false,
    );
  }

  void _onDestinationSelected(int index, bool isAnonymous) {
    if (isAnonymous && index != 0) {
      AppNavigator.goToLogin(context);
      return;
    }
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).currentUser;
    final isAnonymous = user == null;
    final pages = <Widget>[
      BoatListPage(categoriasIniciales: widget.initialCategories),
      const CustomerMapPage(),
      const CustomerChatsPage(),
      const CustomerBookingsPage(),
      isAnonymous
          ? const Center(child: Text('Inicia sesión para ver tu perfil'))
          : const CustomerProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ocean Rent'),
        actions: [
          if (!isAnonymous)
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () {
                mostrarDialogoConfirmacion(
                  context,
                  titulo: 'Cerrar sesión',
                  mensaje: '¿Quieres cerrar sesión?',
                  onAceptar: () {
                    _logout(context, ref);
                  },
                );
              },
            ),
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        decoration: AppTheme.bottomNavigationDecoration,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              _onDestinationSelected(index, isAnonymous),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'Reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
