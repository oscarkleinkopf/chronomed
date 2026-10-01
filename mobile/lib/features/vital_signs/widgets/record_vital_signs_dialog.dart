import 'package:flutter/material.dart';
import '../../../core/storage/local_storage_service.dart';
import '../models/vital_sign_entry.dart';

class RecordVitalSignsDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const RecordVitalSignsDialog({
    super.key,
    this.onSaved,
  });

  static Future<bool?> show(BuildContext context, {VoidCallback? onSaved}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RecordVitalSignsDialog(onSaved: onSaved),
    );
  }

  @override
  State<RecordVitalSignsDialog> createState() => _RecordVitalSignsDialogState();
}

class _RecordVitalSignsDialogState extends State<RecordVitalSignsDialog> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _notesController = TextEditingController();

  GlucoseMealContext _mealContext = GlucoseMealContext.fasting;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _systolicController.addListener(() => setState(() {}));
    _diastolicController.addListener(() => setState(() {}));
    _glucoseController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _glucoseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  VitalSignEntry _buildCurrentDraft() {
    final sys = int.tryParse(_systolicController.text.trim());
    final dia = int.tryParse(_diastolicController.text.trim());
    final hr = int.tryParse(_heartRateController.text.trim());
    final gluc = double.tryParse(_glucoseController.text.trim());

    return VitalSignEntry(
      id: 'vital-${DateTime.now().millisecondsSinceEpoch}',
      patientId: LocalStorageService.instance.activePatientId,
      timestamp: DateTime.now(),
      systolic: sys,
      diastolic: dia,
      heartRate: hr,
      bloodGlucose: gluc,
      mealContext: _mealContext,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
  }

  Future<void> _save() async {
    final entry = _buildCurrentDraft();

    if (!entry.hasBloodPressure && !entry.hasGlucose && !entry.hasHeartRate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Ingresa al menos una medición (Presión, Glicemia o Pulso).'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await LocalStorageService.instance.recordVitalSign(entry);
    widget.onSaved?.call();

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Signos vitales de ${LocalStorageService.instance.patientName} registrados.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _buildCurrentDraft();
    final bpStatus = draft.bloodPressureStatus;
    final bpLabel = draft.bloodPressureLabel;
    final bpColor = draft.bloodPressureColor;

    final glucStatus = draft.glucoseStatus;
    final glucLabel = draft.glucoseLabel;
    final glucColor = draft.glucoseColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFF2563EB), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registrar Signos Vitales',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Paciente: ${LocalStorageService.instance.patientName}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // SECCIÓN: PRESIÓN ARTERIAL & PULSO
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🩺 Presión Arterial (AHA/MINSAL)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        if (bpStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bpColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: bpColor),
                            ),
                            child: Text(
                              bpLabel,
                              style: TextStyle(color: bpColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _systolicController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Sistólica',
                              hintText: '120',
                              suffixText: 'mmHg',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('/', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _diastolicController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Diastólica',
                              hintText: '80',
                              suffixText: 'mmHg',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _heartRateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Frecuencia Cardíaca (Pulso)',
                        hintText: '72',
                        suffixText: 'lpm',
                        prefixIcon: const Icon(Icons.favorite_rounded, color: Color(0xFFDC2626), size: 20),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // SECCIÓN: GLICEMIA CAPILAR
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🩸 Glicemia Capilar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        if (glucStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: glucColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: glucColor),
                            ),
                            child: Text(
                              glucLabel,
                              style: TextStyle(color: glucColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _glucoseController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Nivel de Glucosa',
                        hintText: '95',
                        suffixText: 'mg/dL',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Momento de la toma:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('En ayunas'),
                          selected: _mealContext == GlucoseMealContext.fasting,
                          onSelected: (sel) {
                            if (sel) setState(() => _mealContext = GlucoseMealContext.fasting);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Postprandial (post comida)'),
                          selected: _mealContext == GlucoseMealContext.postprandial,
                          onSelected: (sel) {
                            if (sel) setState(() => _mealContext = GlucoseMealContext.postprandial);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Aleatoria'),
                          selected: _mealContext == GlucoseMealContext.random,
                          onSelected: (sel) {
                            if (sel) setState(() => _mealContext = GlucoseMealContext.random);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // NOTAS
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observaciones clínicas (opcional)',
                  hintText: 'Ej: Tomado tras 10 min de reposo, en brazo izquierdo',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // BOTONES DE ACCIÓN
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Guardar Registro', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
