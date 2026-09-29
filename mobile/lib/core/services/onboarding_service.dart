import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OnboardingService {
  static final OnboardingService instance = OnboardingService._internal();

  OnboardingService._internal();

  bool _isOnboardingCompleted = false;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/chronomed_onboarding.json');
  }

  Future<void> init() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        _isOnboardingCompleted = data['completed'] ?? false;
      }
    } catch (e) {
      print('Error initializing onboarding service: $e');
      _isOnboardingCompleted = false;
    }
  }

  Future<void> completeOnboarding() async {
    _isOnboardingCompleted = true;
    try {
      final file = await _getFile();
      final data = {'completed': true};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving onboarding state: $e');
    }
  }
}
