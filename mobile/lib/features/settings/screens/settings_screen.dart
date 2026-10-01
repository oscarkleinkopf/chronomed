import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/rut_validator.dart';
import '../../../core/api/api_client.dart';

/// Pantalla de configuración general de ChronoMed.
/// Permite gestionar los datos del paciente, PIN de acceso del cuidador,
/// restablecimiento de información y visualización de la versión.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _patientFormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rutController;
  late TextEditingController _pinController;
  late TextEditingController _cloudServerUrlController;
  late TextEditingController _cloudApiKeyController;

  bool _obscurePin = true;
  bool _isSavingPatient = false;
  bool _isResetting = false;
  late bool _cloudBackupEnabled;
  bool _isSavingCloud = false;
  bool _isTestingCloud = false;
  bool _isSyncingCloud = false;
  String? _cloudConnectionStatus;
  bool? _cloudConnectionSuccess;

  @override
  void initState() {
    super.initState();
    final storage = LocalStorageService.instance;
    _nameController = TextEditingController(text: storage.patientName);
    _rutController = TextEditingController(text: storage.patientRut);
    _pinController = TextEditingController(text: storage.caregiverPin);
    _cloudBackupEnabled = storage.cloudBackupEnabled;
    _cloudServerUrlController = TextEditingController(text: storage.cloudServerUrl);
    _cloudApiKeyController = TextEditingController(text: storage.cloudApiKey ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rutController.dispose();
    _pinController.dispose();
    _cloudServerUrlController.dispose();
    _cloudApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _savePatientData() async {
    if (!_patientFormKey.currentState!.validate()) return;

    setState(() => _isSavingPatient = true);
    try {
      await LocalStorageService.instance.savePatientData(
        name: _nameController.text.trim(),
        rut: _rutController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos del paciente guardados correctamente.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar datos: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingPatient = false);
      }
    }
  }

  Future<void> _saveCloudConfig() async {
    setState(() => _isSavingCloud = true);
    try {
      await LocalStorageService.instance.setCloudConfig(
        enabled: _cloudBackupEnabled,
        serverUrl: _cloudServerUrlController.text.trim(),
        apiKey: _cloudApiKeyController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración de respaldo en la nube guardada.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar configuración: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingCloud = false);
    }
  }

  Future<void> _testCloudConnection() async {
    setState(() {
      _isTestingCloud = true;
      _cloudConnectionStatus = null;
      _cloudConnectionSuccess = null;
    });

    final url = _cloudServerUrlController.text.trim();
    final isOnline = await ApiClient.instance.testConnection(customUrl: url);

    if (!mounted) return;
    setState(() {
      _isTestingCloud = false;
      _cloudConnectionSuccess = isOnline;
      _cloudConnectionStatus = isOnline
          ? 'Servidor en línea y alcanzable'
          : 'No se pudo conectar al servidor';
    });
  }

  Future<void> _syncCloudNow() async {
    setState(() => _isSyncingCloud = true);
    // Guardar primero la configuración actual en storage
    await LocalStorageService.instance.setCloudConfig(
      enabled: _cloudBackupEnabled,
      serverUrl: _cloudServerUrlController.text.trim(),
      apiKey: _cloudApiKeyController.text.trim(),
    );

    final success = await ApiClient.instance.pushFullSync();

    if (!mounted) return;
    setState(() => _isSyncingCloud = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Sincronización en la nube completada exitosamente!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo sincronizar. Comprueba la URL y que el backend esté activo.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showChangePinDialog() async {
    final dialogPinController = TextEditingController();
    final dialogConfirmPinController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool obscureDialogPin = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'Cambiar PIN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: dialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingresa un nuevo PIN de 4 dígitos para acceder al Modo Cuidador y ajustes.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dialogPinController,
                        keyboardType: TextInputType.number,
                        obscureText: obscureDialogPin,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Nuevo PIN',
                          hintText: '4 dígitos',
                          counterText: '',
                          prefixIcon: const Icon(Icons.pin, color: Color(0xFF2563EB)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureDialogPin ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureDialogPin = !obscureDialogPin;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un PIN';
                          }
                          if (value.trim().length != 4) {
                            return 'El PIN debe tener 4 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dialogConfirmPinController,
                        keyboardType: TextInputType.number,
                        obscureText: obscureDialogPin,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Confirmar nuevo PIN',
                          hintText: 'Repite los 4 dígitos',
                          counterText: '',
                          prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF2563EB)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Confirma el nuevo PIN';
                          }
                          if (value.trim() != dialogPinController.text.trim()) {
                            return 'Los PIN ingresados no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogFormKey.currentState!.validate()) {
                      final newPin = dialogPinController.text.trim();
                      await LocalStorageService.instance.updateCaregiverPin(newPin);
                      if (mounted) {
                        setState(() {
                          _pinController.text = newPin;
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PIN actualizado exitosamente.'),
                            backgroundColor: Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmResetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Restablecer todos los datos?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Esta acción borrará de forma permanente todos los medicamentos, registros de tomas y configuraciones de la aplicación.\n\nEsta operación no se puede revertir.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sí, restablecer todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isResetting = true);
      try {
        await LocalStorageService.instance.resetAllData();
        final storage = LocalStorageService.instance;
        if (!mounted) return;
        setState(() {
          _nameController.text = storage.patientName;
          _rutController.text = storage.patientRut;
          _pinController.text = storage.caregiverPin;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se han restablecido todos los datos.'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al restablecer datos: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isResetting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);
    const borderColor = Color(0xFFE2E8F0);
    const textDarkColor = Color(0xFF0F172A);
    const textMutedColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: textDarkColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: borderColor,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            // 1. SECCIÓN: DATOS DEL PACIENTE
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.person_outline_rounded, color: primaryColor),
                    ),
                    title: Text(
                      'Datos del Paciente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDarkColor,
                      ),
                    ),
                    subtitle: Text(
                      'Información personal para reportes e identificación',
                      style: TextStyle(fontSize: 12, color: textMutedColor),
                    ),
                  ),
                  const Divider(color: borderColor, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _patientFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Nombre completo',
                              hintText: 'Ej: Juan Pérez González',
                              prefixIcon: const Icon(Icons.badge_outlined, color: primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingresa el nombre del paciente';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _rutController,
                            keyboardType: TextInputType.text,
                            onEditingComplete: () {
                              final raw = _rutController.text;
                              if (raw.isNotEmpty && RutValidator.isValid(raw)) {
                                _rutController.text = RutValidator.format(raw);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'RUT',
                              hintText: 'Ej: 12.345.678-9',
                              prefixIcon: const Icon(Icons.credit_card_outlined, color: primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                            validator: RutValidator.validate,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isSavingPatient ? null : _savePatientData,
                            icon: _isSavingPatient
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_isSavingPatient ? 'Guardando...' : 'Guardar cambios'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. SECCIÓN: MODO SENIOR
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.elderly_rounded, color: primaryColor),
                    ),
                    title: Text(
                      'Modo Senior',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDarkColor,
                      ),
                    ),
                    subtitle: Text(
                      'Control de acceso protegido por PIN para cuidadores',
                      style: TextStyle(fontSize: 12, color: textMutedColor),
                    ),
                  ),
                  const Divider(color: borderColor, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _pinController,
                          readOnly: true,
                          obscureText: _obscurePin,
                          decoration: InputDecoration(
                            labelText: 'PIN de Cuidador actual',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin ? Icons.visibility_off : Icons.visibility,
                                color: textMutedColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePin = !_obscurePin;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            fillColor: const Color(0xFFF8FAFC),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _showChangePinDialog,
                          icon: const Icon(Icons.key_rounded, size: 18),
                          label: const Text('Cambiar PIN'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 20),

            // 3. SECCIÓN: RESPALDO EN LA NUBE (CLOUD SYNC)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.cloud_sync_rounded, color: primaryColor),
                    ),
                    title: Text(
                      'Respaldo en la Nube',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDarkColor,
                      ),
                    ),
                    subtitle: Text(
                      'Sincronización segura opcional (Leyes N° 20.584 y 19.628)',
                      style: TextStyle(fontSize: 12, color: textMutedColor),
                    ),
                  ),
                  const Divider(color: borderColor, height: 1),
                  SwitchListTile(
                    value: _cloudBackupEnabled,
                    onChanged: (val) {
                      setState(() => _cloudBackupEnabled = val);
                      LocalStorageService.instance.setCloudConfig(enabled: val);
                    },
                    activeColor: primaryColor,
                    title: const Text(
                      'Habilitar Respaldo en la Nube',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textDarkColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Permite a cuidadores remotos acceder al estado del paciente',
                      style: TextStyle(fontSize: 12, color: textMutedColor),
                    ),
                  ),
                  if (_cloudBackupEnabled) ...[
                    const Divider(color: borderColor, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _cloudServerUrlController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: 'URL del Servidor Backend',
                              hintText: 'http://localhost:3000/api/v1',
                              prefixIcon: const Icon(Icons.dns_rounded, color: primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _cloudApiKeyController,
                            decoration: InputDecoration(
                              labelText: 'Token de Autenticación (Opcional)',
                              hintText: 'Bearer token o clave de cuidador',
                              prefixIcon: const Icon(Icons.key_rounded, color: primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Estado de Conexión y Última Sincronización
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _cloudConnectionSuccess == true
                                          ? Icons.check_circle_rounded
                                          : (_cloudConnectionSuccess == false
                                              ? Icons.error_rounded
                                              : Icons.cloud_queue_rounded),
                                      size: 16,
                                      color: _cloudConnectionSuccess == true
                                          ? const Color(0xFF16A34A)
                                          : (_cloudConnectionSuccess == false
                                              ? const Color(0xFFDC2626)
                                              : textMutedColor),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _cloudConnectionStatus ?? 'Estado de conexión no comprobado',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _cloudConnectionSuccess == true
                                              ? const Color(0xFF16A34A)
                                              : (_cloudConnectionSuccess == false
                                                  ? const Color(0xFFDC2626)
                                                  : textDarkColor),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  LocalStorageService.instance.lastCloudSync != null
                                      ? 'Última sincronización: ${LocalStorageService.instance.lastCloudSync!.toLocal().toString().substring(0, 16)}'
                                      : 'Última sincronización: Nunca sincronizado',
                                  style: const TextStyle(fontSize: 11, color: textMutedColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Botones de acción
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isTestingCloud ? null : _testCloudConnection,
                                  icon: _isTestingCloud
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.network_check_rounded, size: 16),
                                  label: Text(_isTestingCloud ? 'Probando...' : 'Probar Conexión'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    side: const BorderSide(color: primaryColor),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSyncingCloud ? null : _syncCloudNow,
                                  icon: _isSyncingCloud
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.sync_rounded, size: 16),
                                  label: Text(_isSyncingCloud ? 'Sincronizando...' : 'Sincronizar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isSavingCloud ? null : _saveCloudConfig,
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Guardar Configuración Cloud'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Badge normativo Ley 20.584 y 19.628
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.security_rounded, size: 18, color: Color(0xFF16A34A)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cumplimiento Leyes N° 20.584 y 19.628: Cifrado AES-256-GCM en reposo y Blind Index HMAC-SHA256 para RUT.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF166534),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. SECCIÓN: DATOS
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFFEF2F2),
                      child: Icon(Icons.storage_rounded, color: Color(0xFFDC2626)),
                    ),
                    title: Text(
                      'Datos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDarkColor,
                      ),
                    ),
                    subtitle: Text(
                      'Gestión y limpieza de los datos almacenados',
                      style: TextStyle(fontSize: 12, color: textMutedColor),
                    ),
                  ),
                  const Divider(color: borderColor, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Si restableces los datos, se eliminarán permanentemente todos los medicamentos guardados, el historial y las preferencias configuradas en el teléfono.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isResetting ? null : _confirmResetAllData,
                          icon: _isResetting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.delete_forever_rounded),
                          label: Text(_isResetting ? 'Restableciendo...' : 'Restablecer todos los datos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. SECCIÓN: ACERCA DE
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderColor),
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.info_outline_rounded, color: primaryColor),
                    ),
                    title: Text(
                      'Acerca de',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDarkColor,
                      ),
                    ),
                  ),
                  const Divider(color: borderColor, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: const Icon(
                            Icons.medication_rounded,
                            size: 32,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ChronoMed v1.0.0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDarkColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Adherencia medicamentosa para adultos mayores',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: textMutedColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: borderColor, height: 1),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.menu_book_rounded, color: primaryColor),
                          ),
                          title: const Text(
                            'Manual de Usuario Oficial',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDarkColor,
                            ),
                          ),
                          subtitle: const Text(
                            'Guía interactiva, modo offline y descarga PDF',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMutedColor,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: textMutedColor),
                          onTap: () => context.push('/manual'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
