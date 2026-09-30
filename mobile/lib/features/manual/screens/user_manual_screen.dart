import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/standard_theme.dart';

class ManualChapter {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String tag;
  final String summary;
  final List<ManualSectionItem> items;

  const ManualChapter({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.tag,
    required this.summary,
    required this.items,
  });
}

class ManualSectionItem {
  final String subtitle;
  final String content;
  final String? clinicalTip;

  const ManualSectionItem({
    required this.subtitle,
    required this.content,
    this.clinicalTip,
  });
}

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({super.key});

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<ManualChapter> _chapters = const [
    ManualChapter(
      id: 'legal',
      title: '1. Marco Sanitario y Advertencias Legales',
      icon: Icons.gavel_rounded,
      color: Color(0xFFDC2626),
      tag: 'LEGAL & CLÍNICO',
      summary: 'Regulación chilena, responsabilidad médica y canal de urgencias vitales.',
      items: [
        ManualSectionItem(
          subtitle: 'Ley N° 20.584 (Derechos y Deberes del Paciente)',
          content: 'ChronoMed es una herramienta de apoyo organizativo de la farmacoterapia prescrita. No prescribe medicamentos, no efectúa diagnósticos clínicos ni modifica tratamientos de forma autónoma. Toda pauta farmacológica debe provenir de un profesional habilitado.',
          clinicalTip: 'La confirmación en la app debe corresponder al acto real de ingesta del medicamento.',
        ),
        ManualSectionItem(
          subtitle: 'Ley N° 19.628 (Protección de Datos Sensibles)',
          content: 'Toda la información del paciente se custodia en el dispositivo mediante cifrado militar autenticado AES-256-GCM y búsquedas anonimizadas mediante Blind Indexing HMAC-SHA256. Cero telemetría médica en la nube.',
        ),
        ManualSectionItem(
          subtitle: 'Canal de Urgencia Vital: SAMU 131 y CITUC',
          content: 'Ante intoxicaciones accidentales o reacciones alérgicas severas, comuníquese de inmediato al SAMU 131 (llamada gratuita nacional) o al CITUC UC (+56 2 2635 3800).',
          clinicalTip: 'El botón de auxilio rápido en la barra superior permite consultar los datos de contacto del SAMU.',
        ),
      ],
    ),
    ManualChapter(
      id: 'senior_mode',
      title: '2. Guía de Uso: Modo Senior (Simple)',
      icon: Icons.elderly_rounded,
      color: Color(0xFFD97706),
      tag: 'ACCESIBILIDAD AAA',
      summary: 'Interfaz de cero fricción cognitiva para adultos mayores con temblor o déficit visual.',
      items: [
        ManualSectionItem(
          subtitle: 'Pantalla Única y Botón Táctil de 96 dp',
          content: 'Diseñado bajo la norma WCAG AAA. El adulto mayor solo ve la pastilla que le toca en la franja actual y un botón gigante "YA ME LA TOMÉ" de 96 dp de altura para evitar toques fallidos.',
        ),
        ManualSectionItem(
          subtitle: 'Asistencia Auditiva por Voz TTS',
          content: 'Al presionar el botón de altavoz amarillo, la síntesis de voz en español chileno lee en voz alta el nombre del medicamento, la dosis y la indicación clínica (ej. "Tómate tu Losartán de 50 miligramos con un vaso de agua").',
        ),
        ManualSectionItem(
          subtitle: 'Ficha Físico-Visual de la Pastilla',
          content: 'Muestra la forma exacta (redonda, ovalada, cápsula), el color real (blanco, amarillo, azul) y las ranuras de partición para que el paciente la distinga fácilmente en su mano.',
        ),
      ],
    ),
    ManualChapter(
      id: 'overdose_guard',
      title: '3. Bloqueo Anti-Sobredosis y Escalamiento',
      icon: Icons.shield_rounded,
      color: Color(0xFF059669),
      tag: 'SEGURIDAD VITAL',
      summary: 'Inhabilitación inmediata tras la ingesta y protocolo de alerta a familiares a los 45 min.',
      items: [
        ManualSectionItem(
          subtitle: 'Bloqueo Circadiano Anti-Duplicación',
          content: 'Una vez confirmada la dosis, el botón se bloquea de inmediato cambiando a "¡DOSIS TOMADA!" con un ticket verde. Es físicamente imposible registrar dos tomas seguidas por confusión cognitiva o desmemoria.',
        ),
        ManualSectionItem(
          subtitle: 'Protocolo de Escalamiento a los 45 Minutos',
          content: 'Si transcurren 45 minutos sin que el senior confirme la toma, se dispara una notificación prioritaria al cuidador y se despliega una tarjeta de alerta en el panel clínico.',
          clinicalTip: 'El cuidador puede avisar al paciente o pulsar "Avisar por WhatsApp" para enviar una solicitud formal de verificación.',
        ),
      ],
    ),
    ManualChapter(
      id: 'caregiver_home',
      title: '4. Modo Cuidador y Supervisión Clínica',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF2563EB),
      tag: 'PANEL FAMILIAR',
      summary: 'Consola central de supervisión, resumen de paciente y seguimiento visual semanal.',
      items: [
        ManualSectionItem(
          subtitle: 'Ficha Resumen y Próxima Toma',
          content: 'Permite visualizar en tiempo real el nombre del paciente, su RUT verificado, porcentaje de cumplimiento y la hora exacta del siguiente fármaco programado.',
        ),
        ManualSectionItem(
          subtitle: 'Timeline Semanal de Cumplimiento (7 Días)',
          content: 'Muestra de lunes a domingo el avance del tratamiento con círculos verdes (completas), amarillos (parciales) y rojos (omitidas). El día en curso aparece iluminado con borde azul.',
        ),
      ],
    ),
    ManualChapter(
      id: 'circadian_routine',
      title: '5. Régimen Circadiano: Las 4 Comidas',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF0284C7),
      tag: 'HORARIOS & HOSPITAL',
      summary: 'Adaptación clínica de horarios entre la rutina hogareña y la hospitalaria o ELEAM.',
      items: [
        ManualSectionItem(
          subtitle: 'Presintonía Hogar vs. Hospital / ELEAM',
          content: 'El selector de régimen permite alternar entre horarios domésticos habituales (Desayuno 08:00, Almuerzo 13:30, Once 18:30, Noche 22:30) y horarios hospitalarios tempranos (Desayuno 07:00, Almuerzo 12:00, Cena 17:30, Noche 20:30).',
        ),
        ManualSectionItem(
          subtitle: 'Adelanto Automático de Medicamentos en Ayunas',
          content: 'Al seleccionar el régimen hospitalario, los fármacos de ayunas como Levotiroxina (Eutirox) se reprograman automáticamente a las 06:30 hrs (30 minutos antes de la bandeja de desayuno).',
          clinicalTip: 'Todas las alarmas exactas del sistema se reprograman en segundo plano sin intervención manual.',
        ),
      ],
    ),
    ManualChapter(
      id: 'settings_security',
      title: '6. Ajustes, RUT Módulo 11 y Gestión de PIN',
      icon: Icons.tune_rounded,
      color: Color(0xFF7C3AED),
      tag: 'CONFIGURACIÓN',
      summary: 'Validación nacional de RUT, PIN de protección infantil/senior y reseteo seguro.',
      items: [
        ManualSectionItem(
          subtitle: 'Algoritmo Oficial Módulo 11 (RutValidator)',
          content: 'Valida estrictamente el cuerpo numérico y dígito verificador (0-9 y K) con ponderadores 2 a 7, autoformateando la entrada con puntos y guión (ej. 14.567.890-K).',
        ),
        ManualSectionItem(
          subtitle: 'PIN de Cuidador (4 Dígitos)',
          content: 'Protege el acceso al Modo Senior y evita que el adulto mayor cierre la aplicación o altere el régimen terapéutico sin autorización.',
        ),
        ManualSectionItem(
          subtitle: 'Restablecimiento Total de Datos',
          content: 'Permite purgar la base de datos local y restaurar el sistema a valores de fábrica bajo confirmación explícita (derecho de cancelación Ley N° 19.628).',
        ),
      ],
    ),
    ManualChapter(
      id: 'ocr_interactions',
      title: '7. Escáner OCR y Seguridad Farmacológica',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFF0D9488),
      tag: 'INTELIGENCIA LOCAL',
      summary: 'Lectura óptica de recetas y empaques ISP con detección de contraindicaciones.',
      items: [
        ManualSectionItem(
          subtitle: 'Escaneo On-Device con Google ML Kit',
          content: 'La cámara extrae el nombre comercial, principio activo, concentración (ej. 50 mg, 100 mcg) e intervalos de toma sin enviar fotos a servidores externos.',
        ),
        ManualSectionItem(
          subtitle: 'Matriz de Interacciones y Alertas Rojas',
          content: 'Cruza cada nuevo medicamento contra la lista activa: detecta contraindicaciones críticas como Ibuprofeno + Acenocumarol (riesgo de hemorragia) o Atorvastatina + Claritromicina (rabdomiólisis), bloqueando el registro peligroso.',
        ),
        ManualSectionItem(
          subtitle: 'Restricciones de Alimentos (Lácteos y Alcohol)',
          content: 'Alerta sobre la incompatibilidad de Levotiroxina con lácteos (separar 60 min) y Metformina con alcohol (riesgo de acidosis láctica grave).',
        ),
      ],
    ),
    ManualChapter(
      id: 'pharmacy_stock',
      title: '8. Botiquín y Predictor de Fin de Semana',
      icon: Icons.medication_rounded,
      color: Color(0xFFEA580C),
      tag: 'INVENTARIO & BOTIQUÍN',
      summary: 'Proyección matemática de existencias, compras anticipadas y botón Deshacer.',
      items: [
        ManualSectionItem(
          subtitle: 'Algoritmo de Fines de Semana y Feriados en Chile',
          content: 'Si una caja de pastillas se agotará en domingo o sábado, ChronoMed desplaza la alerta al jueves previo, permitiendo retirar o comprar los fármacos antes del cierre de consultorios CESFAM y farmacias.',
        ),
        ManualSectionItem(
          subtitle: 'Borrado Seguro con Acción DESHACER',
          content: 'Al eliminar un medicamento del botiquín, se solicita confirmación modal y se muestra un SnackBar con el botón interactivo "DESHACER" para recuperar el ítem en 4 segundos si fue un error.',
        ),
      ],
    ),
    ManualChapter(
      id: 'clinical_report',
      title: '9. Informes Clínicos Certificados (PDF)',
      icon: Icons.picture_as_pdf_rounded,
      color: Color(0xFF2563EB),
      tag: 'AUDITORÍA MÉDICA',
      summary: 'Documento vectorizado con firma criptográfica HMAC-SHA256 para el médico tratante.',
      items: [
        ManualSectionItem(
          subtitle: 'Firma Criptográfica HMAC-SHA256',
          content: 'Cada reporte genera un sello de integridad que concatena el nombre, RUT, fecha y porcentaje de cumplimiento. Si alguien altera el PDF impreso o digital, el código no coincide.',
        ),
        ManualSectionItem(
          subtitle: 'Envío en 1 Toque a WhatsApp',
          content: 'Permite compartir el informe clínico directamente al WhatsApp del médico de cabecera, geriatra o familiar de relevo con un mensaje formal estructurado.',
        ),
      ],
    ),
    ManualChapter(
      id: 'offline_sync',
      title: '10. Operación Offline y Sincronización P2P',
      icon: Icons.wifi_off_rounded,
      color: Color(0xFF475569),
      tag: 'SOBERANÍA DE DATOS',
      summary: 'Funcionamiento autónomo sin internet y enlace directo dispositivo a dispositivo.',
      items: [
        ManualSectionItem(
          subtitle: 'Arquitectura 100% Offline-First',
          content: 'La aplicación no depende de conexión de datos ni nube para emitir alarmas exactas o registrar dosis. Las alarmas usan AlarmManager en Android (exactAllowWhileIdle).',
        ),
        ManualSectionItem(
          subtitle: 'Sincronización P2P Local (Wi-Fi / BLE)',
          content: 'El teléfono del cuidador y del adulto mayor se sincronizan mediante intercambio soberano en la red doméstica local o Bluetooth BLE sin pasar por servidores remotos.',
        ),
      ],
    ),
    ManualChapter(
      id: 'faq_troubleshooting',
      title: '11. Preguntas Frecuentes y Solución de Problemas',
      icon: Icons.help_outline_rounded,
      color: Color(0xFF0F172A),
      tag: 'SOPORTE TÉCNICO',
      summary: 'Optimización de batería OEM (Xiaomi, Samsung, Huawei) y permisos Android.',
      items: [
        ManualSectionItem(
          subtitle: '¿Las alarmas no suenan con la pantalla apagada?',
          content: 'En Android (especialmente MIUI/HyperOS, OneUI y EMUI), debe desactivar la optimización de batería agresiva y otorgar permiso de "Alarmas y recordatorios exactos". En Ajustes > Aplicaciones > ChronoMed > Batería > Seleccione "Sin restricciones".',
          clinicalTip: 'Active también la opción "Inicio automático" en dispositivos Xiaomi y Huawei.',
        ),
        ManualSectionItem(
          subtitle: '¿Puedo exportar el manual completo en PDF?',
          content: 'Sí. Utilice el botón "Compartir PDF Oficial" ubicado en la cabecera superior de esta pantalla para enviar o descargar el archivo completo de alta calidad.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sharePdfManual() {
    const manualUrl = 'https://oscarkleinkopf.github.io/chronomed/ChronoMed_Manual_de_Usuario_v1.0.0.pdf';
    Share.share(
      '📘 *Manual de Usuario Maestro — ChronoMed v1.0.0*\n'
      'Plataforma de Cronofarmacología, Adherencia y Seguridad Sanitaria.\n\n'
      'Descarga el manual oficial completo en alta calidad gráfica (PDF):\n'
      '$manualUrl\n\n'
      'Conforme a Leyes N° 20.584 y 19.628 de Chile • SAMU 131',
      subject: 'Manual de Usuario ChronoMed v1.0.0 (PDF)',
    );
  }

  void _showSamuDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 10),
            Text("Urgencias SAMU 131", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Ante sobredosis accidental, sospecha de intoxicación aguda o reacción adversa con riesgo vital:",
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(0xFFDC2626),
                child: Icon(Icons.phone_in_talk_rounded, color: Colors.white),
              ),
              title: Text("SAMU: 131", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text("Llamada gratuita nacional desde cualquier teléfono"),
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(0xFF2563EB),
                child: Icon(Icons.medical_services_rounded, color: Colors.white),
              ),
              title: Text("CITUC UC: +56 2 2635 3800", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("Toxicología y farmacovigilancia 24/7"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ENTENDIDO", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredChapters = _chapters.where((chap) {
      if (query.isEmpty) return true;
      final matchTitle = chap.title.toLowerCase().contains(query);
      final matchSummary = chap.summary.toLowerCase().contains(query);
      final matchTag = chap.tag.toLowerCase().contains(query);
      final matchItems = chap.items.any((item) =>
          item.subtitle.toLowerCase().contains(query) ||
          item.content.toLowerCase().contains(query) ||
          (item.clinicalTip?.toLowerCase().contains(query) ?? false));
      return matchTitle || matchSummary || matchTag || matchItems;
    }).toList();

    return Scaffold(
      backgroundColor: StandardTheme.surfaceLight,
      appBar: AppBar(
        title: const Text("Manual de Usuario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Compartir PDF Oficial',
            onPressed: _sharePdfManual,
          ),
          IconButton(
            icon: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Urgencias SAMU 131',
            onPressed: _showSamuDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text("⏰", style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "ChronoMed Guía Oficial",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Versión 1.0.0 (Release Producción) • Ley 20.584",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  "Manual de usuario interactivo y 100% disponible fuera de línea. Diseñado para cuidadores, familiares y personal geriátrico.",
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text("Compartir PDF", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _sharePdfManual,
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF87171),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.emergency_rounded, size: 18),
                      label: const Text("SAMU 131", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _showSamuDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Buscar en el manual (ej. RUT, bloqueo, OCR, hospital)...",
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results counter if searching
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Resultados para \"$_searchQuery\": ${filteredChapters.length} capítulo(s)",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ),

          // Chapters List
          if (filteredChapters.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text("No se encontraron resultados", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  SizedBox(height: 4),
                  Text("Intente buscar con términos como 'RUT', 'stock', 'PIN', 'alerta' o 'comidas'.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            )
          else
            ...filteredChapters.map((chapter) => _buildChapterCard(chapter, initiallyExpanded: _searchQuery.isNotEmpty)),

          const SizedBox(height: 24),

          // Bottom Regulatory & Identity Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: const [
                Text(
                  "ChronoMed • Salud Digital Soberana de Chile",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 6),
                Text(
                  "En estricto cumplimiento con la Ley N° 20.584 y Ley N° 19.628. Diseñado con accesibilidad universal WCAG 2.2 AAA.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildChapterCard(ManualChapter chapter, {bool initiallyExpanded = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: chapter.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(chapter.icon, color: chapter.color, size: 22),
          ),
          title: Text(
            chapter.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Text(chapter.summary, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: chapter.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  chapter.tag,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: chapter.color),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFF1F5F9)),
                  ...chapter.items.map((item) => _buildSectionItem(item)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem(ManualSectionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 8),
                child: Icon(Icons.arrow_right_rounded, size: 20, color: Color(0xFF2563EB)),
              ),
              Expanded(
                child: Text(
                  item.subtitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              item.content,
              style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF475569)),
            ),
          ),
          if (item.clinicalTip != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.clinicalTip!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
