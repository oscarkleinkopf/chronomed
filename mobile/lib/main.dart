import 'package:flutter/material.dart';
import 'core/theme/standard_theme.dart';
import 'core/theme/senior_theme.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/ocr_history_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.instance.init();
  await OnboardingService.instance.init();
  await OcrHistoryService.instance.init();
  runApp(const ChronoMedApp());
}

class ChronoMedApp extends StatelessWidget {
  const ChronoMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChronoMed',
      debugShowCheckedModeBanner: false,
      theme: StandardTheme.lightTheme,
      darkTheme: StandardTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
