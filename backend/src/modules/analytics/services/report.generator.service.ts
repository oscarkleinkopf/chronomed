import * as crypto from 'crypto';

export interface MedicalReportData {
  patientId: string;
  patientAlias: string;
  reportPeriod: string; // ej: "Agosto 2026"
  adherenceRate: number; // ej: 0.96 (96%)
  totalScheduledDoses: number;
  dosesTakenOnTime: number;
  dosesTakenLate: number;
  dosesMissed: number;
  activeMedications: Array<{
    commercialName: string;
    activeIngredient: string;
    dosage: string;
    frequencyHours: number;
  }>;
  auditChainChecksum: string;
}

export class ClinicalReportGeneratorService {
  private readonly signatureSecret: Buffer;

  constructor(signatureSecretHex?: string) {
    const secret = signatureSecretHex || process.env.AUDIT_HMAC_SECRET || 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
    this.signatureSecret = Buffer.from(secret, 'hex');
  }

  public generateReportPayload(data: MedicalReportData) {
    const generatedAt = new Date().toISOString();
    const payloadToSign = [
      data.patientId,
      data.reportPeriod,
      data.adherenceRate.toFixed(2),
      data.totalScheduledDoses,
      data.dosesTakenOnTime,
      data.auditChainChecksum,
      generatedAt,
    ].join('|');

    const digitalSignature = crypto
      .createHmac('sha256', this.signatureSecret)
      .update(payloadToSign)
      .digest('hex');

    return {
      title: 'INFORME DE ADHERENCIA FARMACOLÓGICA Y TRATAMIENTO',
      legalDisclaimer: 'Documento generado de conformidad con la Ley N° 20.584 (Chile) sobre reserva y custodia de la ficha clínica.',
      patientSummary: {
        alias: data.patientAlias,
        period: data.reportPeriod,
        generatedAt,
      },
      metrics: {
        adherencePercentage: `${(data.adherenceRate * 100).toFixed(1)}%`,
        totalScheduled: data.totalScheduledDoses,
        onTime: data.dosesTakenOnTime,
        delayed: data.dosesTakenLate,
        missed: data.dosesMissed,
        clinicalEvaluation: data.adherenceRate >= 0.85 ? 'ÓPTIMA ADHERENCIA CLÍNICA' : 'ADHERENCIA EN RIESGO (REQUIERE SUPERVISIÓN)',
      },
      medications: data.activeMedications,
      integrityVerification: {
        auditChecksum: data.auditChainChecksum,
        digitalSignature,
        verificationNotice: 'Firma criptográfica inalterable generada por ChronoMed Security Core.',
      },
    };
  }
}
