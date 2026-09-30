import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/onboarding_service.dart';
import '../storage/local_storage_service.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/standard_mode/screens/caregiver_home_screen.dart';
import '../../features/senior_mode/screens/senior_single_action_screen.dart';
import '../../features/medicine_cabinet/screens/medicine_cabinet_screen.dart';
import '../../features/ocr/screens/ocr_scan_history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isOnboarded = OnboardingService.instance.isOnboardingCompleted;
      if (!isOnboarded && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      if (isOnboarded && state.matchedLocation == '/onboarding') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const CaregiverHomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/senior',
        name: 'senior',
        builder: (context, state) {
          final storage = LocalStorageService.instance;
          return SeniorSingleActionScreen(
            patientName: storage.patientName,
            caregiverPin: storage.caregiverPin,
          );
        },
      ),
      GoRoute(
        path: '/medicine-cabinet',
        name: 'medicine-cabinet',
        builder: (context, state) => const MedicineCabinetScreen(),
      ),
      GoRoute(
        path: '/ocr-history',
        name: 'ocr-history',
        builder: (context, state) => const OcrScanHistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
