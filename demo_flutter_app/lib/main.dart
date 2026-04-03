import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'providers/app_settings_provider.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/home/home_screen.dart';
import 'screens/routine/routine_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabaseConfig) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  await NotificationService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()..load()),
      ],
      child: const DelixApp(),
    ),
  );
}

class DelixApp extends StatelessWidget {
  const DelixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Delix Cosmetics',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          locale: settings.localeOverride,
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('es'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainShell(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    RoutineScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTabChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
