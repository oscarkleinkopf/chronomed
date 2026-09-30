import 'package:flutter/material.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/utils/rut_validator.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Page 2 State
  String? _selectedRole;

  // Page 3 State
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rutController = TextEditingController();
  String _mealSchedule = 'Estándar';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _rutController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 2) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      // Save to local storage service
      LocalStorageService.instance.savePatientData(
        name: _nameController.text,
        rut: _rutController.text,
      );
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
    context.go('/');
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos del Paciente',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa la información de la persona que tomará los medicamentos.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('Nombre del paciente', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ej: Juan Pérez',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa el nombre';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              const Text('RUT', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rutController,
                decoration: InputDecoration(
                  hintText: 'Ej: 14.567.890-K',
                  helperText: 'Se valida con dígito verificador',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onEditingComplete: () {
                  // Auto-formatear el RUT al perder foco
                  final raw = _rutController.text;
                  if (raw.isNotEmpty && RutValidator.isValid(raw)) {
                    _rutController.text = RutValidator.format(raw);
                  }
                },
                validator: RutValidator.validate,
              ),
              const SizedBox(height: 24),
              
              const Text('Horario habitual de comidas', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Estándar'),
                    selected: _mealSchedule == 'Estándar',
                    onSelected: (selected) {
                      if (selected) setState(() => _mealSchedule = 'Estándar');
                    },
                    selectedColor: const Color(0xFFDBEAFE),
                    labelStyle: TextStyle(
                      color: _mealSchedule == 'Estándar' ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Personalizado'),
                    selected: _mealSchedule == 'Personalizado',
                    onSelected: (selected) {
                      if (selected) setState(() => _mealSchedule = 'Personalizado');
                    },
                    selectedColor: const Color(0xFFDBEAFE),
                    labelStyle: TextStyle(
                      color: _mealSchedule == 'Personalizado' ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _mealSchedule == 'Estándar' 
                    ? 'Desayuno 8:00, Almuerzo 13:00, Once 17:00, Cena 20:00'
                    : 'Podrás ajustarlo más adelante en la configuración.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
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
