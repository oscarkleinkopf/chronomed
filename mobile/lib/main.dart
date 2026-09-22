import 'package:flutter/material.dart';
import 'core/theme/standard_theme.dart';
import 'core/theme/senior_theme.dart';
import 'features/standard_mode/screens/caregiver_home_screen.dart';
import 'features/senior_mode/screens/senior_single_action_screen.dart';

import 'core/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.instance.init();
  runApp(const ChronoMedApp());
}

class ChronoMedApp extends StatelessWidget {
  const ChronoMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoMed',
      debugShowCheckedModeBanner: false,
      theme: StandardTheme.lightTheme,
      darkTheme: SeniorTheme.themeData,
      themeMode: ThemeMode.system,
      home: const CaregiverHomeScreen(),
    );
  }
}
