import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roddar_pneus/theme/theme_provider.dart';
import 'package:roddar_pneus/myapp.dart';
import 'package:roddar_pneus/view/login.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Roddar Pneus',
          theme: themeProvider.themeData,
          home: const LoginPage(),
        );
      },
    );
  }
}
