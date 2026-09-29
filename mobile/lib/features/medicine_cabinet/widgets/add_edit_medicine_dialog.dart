import 'package:flutter/material.dart';
import '../models/medicine_cabinet_item.dart';
import '../../ocr/models/medicine_box_scan_result.dart';

class AddEditMedicineDialog extends StatefulWidget {
  final MedicineCabinetItem? initialItem;
  final Function(MedicineCabinetItem) onSave;

  const AddEditMedicineDialog({
    super.key,
    this.initialItem,
    required this.onSave,
  });

  @override
  State<AddEditMedicineDialog> createState() => _AddEditMedicineDialogState();
}

class _AddEditMedicineDialogState extends State<AddEditMedicineDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;
  late TextEditingController _lotController;
  late TextEditingController _expirationController;
  late TextEditingController _ispController;
  late TextEditingController _imprintController;
  late TextEditingController _descriptionController;

  late bool _isBioequivalent;
  late bool _hasScoreLine;
  late String _shapeType;
  late int _pillColorValue;

  final List<Map<String, dynamic>> _pillColors = [
    {'name': 'Blanco', 'value': 0xFFFFFFFF, 'border': true},
    {'name': 'Azul', 'value': 0xFF3B82F6, 'border': false},
    {'name': 'Amarillo', 'value': 0xFFFACC15, 'border': false},
    {'name': 'Rojo / Rosado', 'value': 0xFFEF4444, 'border': false},
    {'name': 'Verde', 'value': 0xFF10B981, 'border': false},
    {'name': 'Naranja', 'value': 0xFFF97316, 'border': false},
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    _dosageController = TextEditingController(text: item?.dosage ?? '');
    _stockController = TextEditingController(text: (item?.stockUnits ?? 30).toString());
    _lotController = TextEditingController(text: item?.lotNumber ?? '');
    _expirationController = TextEditingController(text: item?.expirationDate ?? '');
    _ispController = TextEditingController(text: item?.ispRegister ?? '');
    _imprintController = TextEditingController(text: item?.imprint ?? '');
    _descriptionController = TextEditingController(text: item?.physicalDescription ?? '');

    _isBioequivalent = item?.isBioequivalent ?? false;
    _hasScoreLine = item?.hasScoreLine ?? false;
    _shapeType = item?.shapeType ?? 'round';
    _pillColorValue = item?.pillColorValue ?? 0xFF3B82F6;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _lotController.dispose();
    _expirationController.dispose();
    _ispController.dispose();
    _imprintController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final units = int.tryParse(_stockController.text.trim()) ?? 0;

    BoxExpirationStatus status = BoxExpirationStatus.unknown;
    if (_expirationController.text.trim().isNotEmpty) {
      status = BoxExpirationStatus.valid;
    }

    final item = MedicineCabinetItem(
      id: widget.initialItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      stockUnits: units < 0 ? 0 : units,
      lotNumber: _lotController.text.trim().isEmpty ? null : _lotController.text.trim(),
      expirationDate: _expirationController.text.trim().isEmpty ? null : _expirationController.text.trim(),
      ispRegister: _ispController.text.trim().isEmpty ? null : _ispController.text.trim(),
      isBioequivalent: _isBioequivalent,
      expirationStatus: status,
      shapeType: _shapeType,
      pillColorValue: _pillColorValue,
      imprint: _imprintController.text.trim(),
      hasScoreLine: _hasScoreLine,
      physicalDescription: _descriptionController.text.trim(),
      createdAt: widget.initialItem?.createdAt ?? DateTime.now(),
    );

    widget.onSave(item);
    Navigator.pop(context);
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      helpText: 'VENCIMIENTO DEL FÁRMACO',
    );
    if (picked != null) {
      final monthStr = picked.month.toString().padLeft(2, '0');
      final yearStr = picked.year.toString();
      setState(() {
        _expirationController.text = '$monthStr/$yearStr';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialItem != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                        color: const Color(0xFF2563EB),
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Editar Medicamento' : 'Nuevo Fármaco en Botiquín',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Content scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del fármaco
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre comercial o genérico *',
                          hintText: 'Ej: Losartán Potásico / Eutirox',
                          prefixIcon: Icon(Icons.medication_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre del fármaco';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Dosis y Unidades
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _dosageController,
                              decoration: const InputDecoration(
                                labelText: 'Dosis / Concentración',
                                hintText: 'Ej: 50 mg, 100 mcg',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock (un.) *',
                                hintText: '30',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || int.tryParse(value.trim()) == null) {
                                  return 'Número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Registro ISP y Bioequivalencia
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ispController,
                              decoration: const InputDecoration(
                                labelText: 'Registro ISP (Chile)',
                                hintText: 'Ej: F-14920/19',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Switch Bioequivalente
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: const [
                            Text(
                              'Bioequivalente ISP Chile',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(width: 6),
                            Text('⭐', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        subtitle: const Text(
                          'Cumple con certificación de bioequivalencia y sello amarillo/rojo del ISP.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        value: _isBioequivalent,
                        activeColor: const Color(0xFFD97706),
                        onChanged: (val) => setState(() => _isBioequivalent = val),
                      ),
                      const Divider(height: 16),

                      // Lote y Fecha de Vencimiento
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lotController,
                              decoration: const InputDecoration(
                                labelText: 'Número de Lote',
                                hintText: 'Ej: 24A09',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _expirationController,
                              keyboardType: TextInputType.datetime,
                              decoration: InputDecoration(
                                labelText: 'Vencimiento (MM/AAAA)',
                                hintText: '12/2028',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF2563EB)),
                                  tooltip: 'Seleccionar fecha',
                                  onPressed: _pickExpirationDate,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final reg = RegExp(r'^(0[1-9]|1[0-2])\/\d{4}$');
                                if (!reg.hasMatch(value.trim())) {
                                  return 'Formato MM/AAAA';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Apariencia física de la pastilla
                      const Text(
                        'Aspecto Físico (Lupa y reconocimiento visual):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Forma
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _shapeType,
                              decoration: const InputDecoration(
                                labelText: 'Forma',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'round', child: Text('Circular normal')),
                                DropdownMenuItem(value: 'small_round', child: Text('Circular pequeña')),
                                DropdownMenuItem(value: 'oblong', child: Text('Oblonga / Alargada')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _shapeType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Grabado
                          Expanded(
                            child: TextFormField(
                              controller: _imprintController,
                              decoration: const InputDecoration(
                                labelText: 'Grabado / Impresión',
                                hintText: 'Ej: 50, 100',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Color selector
                      const Text(
                        'Color de la pastilla:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _pillColors.map((c) {
                          final isSelected = _pillColorValue == c['value'];
                          return GestureDetector(
                            onTap: () => setState(() => _pillColorValue = c['value']),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(c['value']),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [const BoxShadow(color: Color(0x332563EB), blurRadius: 6, spreadRadius: 1)]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color: c['value'] == 0xFFFFFFFF ? Colors.black : Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tiene ranura central de partición (ranurado)'),
                        value: _hasScoreLine,
                        onChanged: (val) => setState(() => _hasScoreLine = val ?? false),
                      ),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción visual física (para lectura por voz y accesibilidad)',
                          hintText: 'Ej: Comprimido circular azul grabado "50" con ranura central',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _save,
                      child: Text(
                        isEditing ? 'GUARDAR CAMBIOS' : 'AGREGAR A BOTIQUÍN',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
