import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:provider/provider.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';

import 'providers/theme_provider.dart';

import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();

  await Hive.openBox(
    "cash_control_local",
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(
      context,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CASH-CONTROL",
      themeMode: themeProvider.themeMode,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: const LoginScreen(),
    );
  }
}