import 'package:flutter/material.dart';
import '../../schedule/models/circadian_routine.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/notifications/alarm_scheduler.dart';

class CaregiverCircadianController extends ChangeNotifier {
  CircadianRoutine _currentRoutine = CircadianRoutine.home;
  CircadianRoutine get currentRoutine => _currentRoutine;

  void loadRoutine() {
    _currentRoutine = LocalStorageService.instance.getCircadianRoutine();
    notifyListeners();
  }

  Future<void> updateRoutine(BuildContext context, CircadianRoutine routine) async {
    _currentRoutine = routine;
    notifyListeners();
    await LocalStorageService.instance.saveCircadianRoutine(_currentRoutine);
    final scheduled = await AlarmScheduler().scheduleAllCircadianAlarms(
      routine: _currentRoutine,
      storage: LocalStorageService.instance,
    );
    if (context.mounted && scheduled > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          content: Text(
            '⏰ Alarmas reprogramadas: $scheduled tomas sincronizadas con ${_currentRoutine.regimeTitle}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> showCustomRoutineDialog(BuildContext context) async {
    TimeOfDay breakfast = _currentRoutine.breakfast;
    TimeOfDay lunch = _currentRoutine.lunch;
    TimeOfDay afternoon = _currentRoutine.afternoon;
    TimeOfDay night = _currentRoutine.night;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Horarios Personalizados"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Text("☀️", style: TextStyle(fontSize: 24)),
                    title: const Text("Desayuno"),
                    trailing: TextButton(
                      child: Text(_currentRoutine.formatTime(breakfast), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: breakfast);
                        if (picked != null) setDialogState(() => breakfast = picked);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Text("🍲", style: TextStyle(fontSize: 24)),
                    title: const Text("Almuerzo"),
                    trailing: TextButton(
                      child: Text(_currentRoutine.formatTime(lunch), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: lunch);
                        if (picked != null) setDialogState(() => lunch = picked);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Text("☕", style: TextStyle(fontSize: 24)),
                    title: const Text("Once"),
                    trailing: TextButton(
                      child: Text(_currentRoutine.formatTime(afternoon), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: afternoon);
                        if (picked != null) setDialogState(() => afternoon = picked);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Text("🌙", style: TextStyle(fontSize: 24)),
                    title: const Text("Noche"),
                    trailing: TextButton(
                      child: Text(_currentRoutine.formatTime(night), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: night);
                        if (picked != null) setDialogState(() => night = picked);
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
              ElevatedButton(
                onPressed: () {
                  final newRoutine = _currentRoutine.copyWith(
                    regimeType: CircadianRegimeType.custom,
                    breakfast: breakfast,
                    lunch: lunch,
                    afternoon: afternoon,
                    night: night,
                  );
                  Navigator.pop(ctx);
                  updateRoutine(context, newRoutine);
                },
                child: const Text("GUARDAR"),
              ),
            ],
          );
        },
      ),
    );
  }
}
