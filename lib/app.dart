import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/views/memorization/screens/global_dashboard_screen.dart';
import 'presentation/views/root_view.dart';

class MyWalkApp extends StatelessWidget {
  const MyWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyWalk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootView(),
      onGenerateRoute: (settings) {
        if (settings.name == '/memorization/global-dashboard') {
          return MaterialPageRoute(
            builder: (_) => const GlobalDashboardScreen(),
          );
        }
        return null;
      },
    );
  }
}
