import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'provider/auth_provider.dart';
import 'provider/theme_provider.dart';
import 'provider/user_provider.dart';
import 'provider/delegation_provider.dart';
import 'provider/group_provider.dart';
import 'provider/category_provider.dart';
import 'provider/tag_provider.dart';
import 'provider/activity_provider.dart';
import 'provider/dashboard_provider.dart';
import 'provider/holiday_provider.dart';
import 'provider/notification_provider.dart';
import 'provider/roles_provider.dart';
import 'provider/task_template_provider.dart';
import 'screen/auth/login/login_screen.dart';
import 'screen/home/wriper_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settingsBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DelegationProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TagProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RolesProvider()),
        ChangeNotifierProvider(create: (_) => TaskTemplateProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        return MaterialApp(
          title: 'D-Table ERP',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: authProvider.isAuthenticated
              ? const MainWrapper()
              : const LoginScreen(),
        );
      },
    );
  }
}
