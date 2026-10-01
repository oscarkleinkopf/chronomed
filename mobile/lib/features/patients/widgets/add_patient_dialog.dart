import 'package:flutter/material.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/rut_validator.dart';
import '../../schedule/models/circadian_routine.dart';
import '../models/patient_profile.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rutController = TextEditingController();
  final _ageController = TextEditingController();

  int _selectedColorValue = 0xFF2563EB; // Azul por defecto
  CircadianRegimeType _selectedRegime = CircadianRegimeType.home;

  static const List<int> _avatarColors = [
    0xFF2563EB, // Azul
    0xFF7C3AED, // Violeta
    0xFF059669, // Esmeralda
    0xFFD97706, // Ámbar
    0xFFE11D48, // Rosa / Rubí
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _rutController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _formatRutOnBlur() {
    final raw = _rutController.text.trim();
    if (raw.isNotEmpty) {
      final formatted = RutValidator.format(raw);
      if (formatted != raw) {
        _rutController.text = formatted;
      }
    }
  }

  Future<void> _savePatient() async {
    _formatRutOnBlur();
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final rut = _rutController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    final routine = _selectedRegime == CircadianRegimeType.hospital
        ? CircadianRoutine.hospital
        : CircadianRoutine.home;

    final newPatient = PatientProfile(
      id: 'patient-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      rut: rut,
      age: age,
      avatarColorValue: _selectedColorValue,
      routine: routine,
      stocks: {
        'eutirox': 28,
        'losartan': 14,
        'atorvastatina': 30,
      },
    );

    await LocalStorageService.instance.addPatient(newPatient, setActive: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Paciente "$name" creado y seleccionado como activo!'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);
    const textDarkColor = Color(0xFF0F172A);
    const borderColor = Color(0xFFCBD5E1);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(_selectedColorValue).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_add_rounded, color: Color(_selectedColorValue), size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo Paciente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDarkColor,
                            ),
                          ),
                          Text(
                            'Registra a otro adulto mayor a tu cuidado',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    hintText: 'Ej. Roberto Gómez',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa el nombre del paciente';
                    if (val.trim().length < 2) return 'El nombre debe tener al menos 2 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // RUT Chileno
                Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) _formatRutOnBlur();
                  },
                  child: TextFormField(
                    controller: _rutController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'RUT Chileno',
                      hintText: 'Ej. 12.345.678-5',
                      prefixIcon: const Icon(Icons.badge_outlined, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: RutValidator.validateField,
                  ),
                ),
                const SizedBox(height: 14),

                // Edad (Opcional)
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Edad (años, opcional)',
                    hintText: 'Ej. 78',
                    prefixIcon: const Icon(Icons.cake_outlined, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de Color de Avatar
                const Text(
                  'Color de Identificación:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _avatarColors.map((colorVal) {
                    final isSelected = _selectedColorValue == colorVal;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorValue = colorVal),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: textDarkColor, width: 3)
                              : Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Color(colorVal).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Régimen Circadiano Inicial
                const Text(
                  'Régimen Circadiano Inicial:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkColor),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, size: 16),
                            SizedBox(width: 4),
                            Text('Hogar (8:00)'),
                          ],
                        ),
                        selected: _selectedRegime == CircadianRegimeType.home,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRegime = CircadianRegimeType.home);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_hospital_rounded, size: 16),
                            SizedBox(width: 4),
                            Text('Hospital (7:30)'),
                          ],
                        ),
                        selected: _selectedRegime == CircadianRegimeType.hospital,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRegime = CircadianRegimeType.hospital);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _savePatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Crear Paciente'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
