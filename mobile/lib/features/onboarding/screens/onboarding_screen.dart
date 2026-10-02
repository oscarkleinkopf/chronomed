import 'package:flutter/material.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/utils/rut_validator.dart';
import '../../schedule/models/circadian_routine.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Page 2 State: Rol del Usuario
  String? _selectedRole = 'cuidador'; // 'cuidador', 'profesional', 'paciente'

  // Page 3 State: Formulario Adaptativo
  final _formKey = GlobalKey<FormState>();

  // Datos Operador (Cuidador / Profesional)
  final _operatorNameController = TextEditingController();
  final _operatorOrgController = TextEditingController();
  final _pinController = TextEditingController(text: '1234');
  String _professionalRole = 'Médico/a Tratante';

  // Datos Paciente / Tratamiento
  final _patientNameController = TextEditingController();
  final _patientRutController = TextEditingController();
  CircadianRegimeType _selectedRegime = CircadianRegimeType.home;

  @override
  void dispose() {
    _pageController.dispose();
    _operatorNameController.dispose();
    _operatorOrgController.dispose();
    _pinController.dispose();
    _patientNameController.dispose();
    _patientRutController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage == 2) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      
      final storage = LocalStorageService.instance;
      final role = _selectedRole ?? 'cuidador';
      
      String patientName = _patientNameController.text.trim();
      String patientRut = _patientRutController.text.trim();
      if (patientName.isEmpty) patientName = 'Marcela';
      if (patientRut.isEmpty) patientRut = '14.567.890-K';

      if (role == 'paciente') {
        await storage.saveUserProfile(
          role: 'autonomous_patient',
          userName: patientName,
          userTitle: 'Paciente Autónomo',
          userOrganization: 'Hogar',
        );
      } else if (role == 'profesional') {
        final profName = _operatorNameController.text.trim().isNotEmpty
            ? _operatorNameController.text.trim()
            : 'Profesional de Salud';
        final org = _operatorOrgController.text.trim().isNotEmpty
            ? _operatorOrgController.text.trim()
            : 'CESFAM';
        await storage.saveUserProfile(
          role: 'professional',
          userName: profName,
          userTitle: _professionalRole,
          userOrganization: org,
          caregiverPin: _pinController.text.trim().isNotEmpty ? _pinController.text.trim() : '1234',
        );
      } else {
        final caregiverName = _operatorNameController.text.trim().isNotEmpty
            ? _operatorNameController.text.trim()
            : 'Cuidador Familiar';
        await storage.saveUserProfile(
          role: 'caregiver',
          userName: caregiverName,
          userTitle: 'Cuidador/a Familiar',
          userOrganization: 'Hogar',
          caregiverPin: _pinController.text.trim().isNotEmpty ? _pinController.text.trim() : '1234',
        );
      }

      await storage.savePatientData(
        name: patientName,
        rut: patientRut,
      );

      final routine = _selectedRegime == CircadianRegimeType.hospital
          ? CircadianRoutine.hospital
          : CircadianRoutine.home;
      await storage.updateCircadianRoutine(routine);
    }

    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    await OnboardingService.instance.completeOnboarding();
    if (!mounted) return;
    if (_selectedRole == 'paciente') {
      context.go('/senior');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar like area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentPage > 0
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2563EB)),
                          onPressed: _prevPage,
                        )
                      : const SizedBox(width: 48), // Placeholder for spacing
                  // Skip button on first few pages? The prompt only mentions Skip on the last page or "Omitir por ahora" for scan.
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Expanded PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce validation
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildRoleSelectionPage(),
                  _buildPatientDataPage(),
                  _buildFirstScanPage(),
                ],
              ),
            ),

            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              size: 100,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'Bienvenido a ChronoMed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Plataforma de adherencia medicamentosa para tu familiar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Quién eres?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona tu rol principal para personalizar tu experiencia.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildRoleCard(
                  icon: '👨‍⚕️',
                  title: 'Cuidador/a Familiar',
                  subtitle: 'Gestiono la medicación de mi familiar',
                  role: 'cuidador',
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  icon: '👩‍⚕️',
                  title: 'Profesional de Salud',
                  subtitle: 'Superviso el tratamiento de mis pacientes',
                  role: 'profesional',
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  icon: '👴',
                  title: 'Paciente (Adulto Mayor)',
                  subtitle: 'Tomo mis propios medicamentos',
                  role: 'paciente',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String icon,
    required String title,
    required String subtitle,
    required String role,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDataPage() {
    final role = _selectedRole ?? 'cuidador';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (role == 'profesional') ...[
                _buildProfessionalHeader(),
                const SizedBox(height: 20),
                _buildProfessionalFields(),
                const SizedBox(height: 20),
                _buildPatientFields(
                  title: 'Primer Paciente en Supervisión',
                  subtitle: 'Ficha clínica del adulto mayor que ingresarás.',
                  nameHint: 'Ej: Marcela Gómez',
                ),
              ] else if (role == 'paciente') ...[
                _buildAutonomousPatientHeader(),
                const SizedBox(height: 20),
                _buildAutonomousPatientFields(),
              ] else ...[
                _buildCaregiverHeader(),
                const SizedBox(height: 20),
                _buildCaregiverFields(),
                const SizedBox(height: 20),
                _buildPatientFields(
                  title: 'Familiar a Cuidar',
                  subtitle: 'Información de tu ser querido que tomará los medicamentos.',
                  nameHint: 'Ej: Marcela',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Configuración de Cuidador/a',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        SizedBox(height: 6),
        Text(
          'Registra tus datos y los de tu familiar para coordinar y asegurar su tratamiento.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildProfessionalHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Registro Profesional de Salud',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        SizedBox(height: 6),
        Text(
          'Supervisión de rondas, adherencia clínica y fichas de salud.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildAutonomousPatientHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Tu Tratamiento Personal',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        SizedBox(height: 6),
        Text(
          'Configura tu nombre y horarios para avisarte por voz y en pantalla grande.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildCaregiverFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text('Tus Datos de Cuidador/a', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Tu Nombre Completo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _operatorNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration('Ej: Carlos Gómez', Icons.person_outline),
          ),
          const SizedBox(height: 14),
          const Text('PIN de Seguridad (4 dígitos)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 4),
          const Text('Para proteger cambios de recetas y ajustes.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: _inputDecoration('1234', Icons.lock_outline),
            validator: (v) {
              if (v == null || v.trim().length != 4) return 'Ingresa un PIN de 4 dígitos';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text('Credenciales Clínicas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Nombre Profesional', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _operatorNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration('Ej: Dra. Sofía Morales / Enf. Rodrigo Silva', Icons.person_pin_outlined),
          ),
          const SizedBox(height: 14),
          const Text('Rol Clínico', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Médico/a Tratante', 'Enfermero/a Clínico/a', 'TENS'].map((r) {
              final sel = _professionalRole == r;
              return ChoiceChip(
                label: Text(r),
                selected: sel,
                onSelected: (s) {
                  if (s) setState(() => _professionalRole = r);
                },
                selectedColor: const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  color: sel ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('Establecimiento o Servicio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _operatorOrgController,
            decoration: _inputDecoration('Ej: CESFAM Santa Julia / ELEAM Los Nogales', Icons.local_hospital_outlined),
          ),
          const SizedBox(height: 14),
          const Text('PIN de Acceso Rápido (4 dígitos)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: _inputDecoration('1234', Icons.lock_outline),
            validator: (v) {
              if (v == null || v.trim().length != 4) return 'Ingresa un PIN de 4 dígitos';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutonomousPatientFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text('Tus Datos Personales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 14),
          const Text('¿Cómo te gusta que te llamen?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _patientNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration('Ej: Roberto Gómez', Icons.person_outline),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Por favor escribe tu nombre';
              return null;
            },
          ),
          const SizedBox(height: 14),
          const Text('Tu RUT Chileno (Opcional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                final raw = _patientRutController.text.trim();
                if (raw.isNotEmpty && RutValidator.isValid(raw)) {
                  _patientRutController.text = RutValidator.format(raw);
                }
              }
            },
            child: TextFormField(
              controller: _patientRutController,
              decoration: _inputDecoration('Ej: 14.567.890-K', Icons.badge_outlined),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  return RutValidator.validateField(v);
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildCircadianRegimeSelector(),
        ],
      ),
    );
  }

  Widget _buildPatientFields({
    required String title,
    required String subtitle,
    required String nameHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_circle_outlined, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          const Text('Nombre Completo del Paciente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _patientNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(nameHint, Icons.person_outline),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Ingresa el nombre del paciente';
              if (val.trim().length < 2) return 'El nombre debe tener al menos 2 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 14),
          const Text('RUT Chileno o N° de Ficha', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                final raw = _patientRutController.text.trim();
                if (raw.isNotEmpty && RutValidator.isValid(raw)) {
                  _patientRutController.text = RutValidator.format(raw);
                }
              }
            },
            child: TextFormField(
              controller: _patientRutController,
              decoration: _inputDecoration('Ej: 14.567.890-K', Icons.badge_outlined),
              validator: RutValidator.validateField,
            ),
          ),
          const SizedBox(height: 16),
          _buildCircadianRegimeSelector(),
        ],
      ),
    );
  }

  Widget _buildCircadianRegimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Régimen Horario Inicial (4 Comidas):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
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
                selectedColor: const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  color: _selectedRegime == CircadianRegimeType.home ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                  fontWeight: _selectedRegime == CircadianRegimeType.home ? FontWeight.bold : FontWeight.normal,
                ),
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
                selectedColor: const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  color: _selectedRegime == CircadianRegimeType.hospital ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                  fontWeight: _selectedRegime == CircadianRegimeType.hospital ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildFirstScanPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Escanea tu primer medicamento',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Agrega el primer medicamento de tu familiar para probar la plataforma.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 48),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Apunta la cámara a la caja de tu medicamento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Logic to open scanner
                    _finishOnboarding();
                  },
                  icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                  label: const Text(
                    'ESCANEAR CAJA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text(
              'Omitir por ahora',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots indicator
          Row(
            children: List.generate(4, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          
          // Next/Start Button
          ElevatedButton(
            onPressed: () {
              if (_currentPage == 1 && _selectedRole == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, selecciona un rol')),
                );
                return;
              }
              _nextPage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _currentPage == 3 ? 'COMENZAR' : 'SIGUIENTE',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
