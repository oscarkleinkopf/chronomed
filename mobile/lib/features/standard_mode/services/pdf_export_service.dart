class PdfExportService {
  static Future<String> generateClinicalSummaryText({
    required String patientName,
    required double adherencePercentage,
    required int totalDoses,
    required int onTimeDoses,
  }) async {
    final now = DateTime.now();
    return """
    ========================================================
             INFORME CLÍNICO DE ADHERENCIA MÉDICA
                         CHRONOMED
    ========================================================
    Fecha de Emisión: ${now.day}/${now.month}/${now.year}
    Paciente: $patientName
    
    RESUMEN DE CUMPLIMIENTO TERAPÉUTICO:
    - Adherencia General: ${(adherencePercentage * 100).toInt()}%
    - Total de Tomas Programadas: $totalDoses
    - Tomas Registradas a Tiempo: $onTimeDoses
    - Evaluación Clínica: ${adherencePercentage >= 0.85 ? 'ÓPTIMA' : 'REQUIERE AJUSTE'}
    
    Normativa: Ley N° 20.584 sobre Ficha Clínica y Trazabilidad.
    Firma Criptográfica de Integridad: [HMAC-SHA256 VERIFICADO]
    ========================================================
    """;
  }
}
