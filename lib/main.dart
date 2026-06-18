import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/auth_gate/auth_gate_page.dart';
import 'package:ocean_rent/services/boat/boat_cache_service.dart';
import 'package:ocean_rent/services/firebase_options.dart';
import 'package:ocean_rent/services/notification/notification_service.dart';
import 'package:ocean_rent/services/stripe/stripe_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await StripeService.initialize();

  await Hive.initFlutter();
  Hive.registerAdapter(BoatModelAdapter());
  await Hive.openBox<BoatModel>('boats');


  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('Firebase inicializado correctamente');
    debugPrint('App Firebase: ${Firebase.app().name}');
  }
  await NotificationService.instance.initialize();

  BoatCacheService().syncWithFirebase();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGatePage(),
    );
  }
}
