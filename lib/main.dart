import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: SwimmingClubApp(),
    ),
  );
}

class SwimmingClubApp extends StatelessWidget {
  SwimmingClubApp({super.key});

  final _router = routerProvider;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Swimming Club',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
