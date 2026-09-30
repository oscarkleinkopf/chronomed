import { ClinicalReportGeneratorService, MedicalReportData } from '../../src/modules/analytics/services/report.generator.service';

describe('ClinicalReportGeneratorService (Ley 20.584)', () => {
  const service = new ClinicalReportGeneratorService('abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789');

  it('debe generar reporte clínico con firma criptográfica y evaluación óptima', () => {
    const data: MedicalReportData = {
      patientId: 'pat-1',
      patientAlias: 'Marcela',
      reportPeriod: 'Septiembre 2026',
      adherenceRate: 0.95,
      totalScheduledDoses: 20,
      dosesTakenOnTime: 19,
      dosesTakenLate: 0,
      dosesMissed: 1,
      activeMedications: [
        {
          commercialName: 'Eutirox 100mcg',
          activeIngredient: 'Levotiroxina',
          dosage: '1 comprimido',
          frequencyHours: 24,
        },
      ],
      auditChainChecksum: 'hash1234567890',
    };

    const report = service.generateReportPayload(data);
    expect(report.title).toBe('INFORME DE ADHERENCIA FARMACOLÓGICA Y TRATAMIENTO');
    expect(report.metrics.clinicalEvaluation).toBe('ÓPTIMA ADHERENCIA CLÍNICA');
    expect(report.integrityVerification.digitalSignature).toBeDefined();
    expect(report.integrityVerification.auditChecksum).toBe('hash1234567890');
  });

  it('debe alertar adherencia en riesgo si es menor al 85%', () => {
    const data: MedicalReportData = {
      patientId: 'pat-2',
      patientAlias: 'Carlos',
      reportPeriod: 'Septiembre 2026',
      adherenceRate: 0.70,
      totalScheduledDoses: 30,
      dosesTakenOnTime: 20,
      dosesTakenLate: 1,
      dosesMissed: 9,
      activeMedications: [],
      auditChainChecksum: 'hashcarlos',
    };

    const report = service.generateReportPayload(data);
    expect(report.metrics.clinicalEvaluation).toBe('ADHERENCIA EN RIESGO (REQUIERE SUPERVISIÓN)');
  });
});
