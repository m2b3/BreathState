import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/providers/theme_provider.dart';
import 'package:breath_state/screens/record_screen.dart';
import 'package:breath_state/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/home_screen.dart';
import 'screens/guided_breathing_screen.dart';

import 'package:breath_state/theme/app_theme.dart';

import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavBarProvider(0)),
        ChangeNotifierProvider(create: (_) => PolarConnectProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Widget> screens = const [
    HomeScreen(),
    RecordScreen(),
    GuidedBreathingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'BreathState',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Consumer<NavBarProvider>(
            builder: (context, model, child) {
              return Scaffold(
                extendBody: true,
                body: screens[model.getIndex()],
                bottomNavigationBar: const BottomNavBar(),
              );
            },
          ),
        );
      },
    );
  }
}
