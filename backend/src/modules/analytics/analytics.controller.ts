import { Controller, Get, NotFoundException, Param } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { ClinicalReportGeneratorService } from './services/report.generator.service';
import { PrismaService } from '../../common/prisma/prisma.service';
import { EncryptionService } from '../security/services/encryption.service';
import { IntakeStatus } from '@prisma/client';

@ApiTags('Clinical Analytics & Audit (Ley 20.584)')
@Controller('analytics')
export class AnalyticsController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryptionService: EncryptionService,
    private readonly reportGenerator: ClinicalReportGeneratorService,
  ) {}

  @Get('patients/:id/report')
  @ApiOperation({ summary: 'Generar reporte clínico de adherencia farmacológica con firma criptográfica' })
  async getComplianceReport(@Param('id') patientId: string) {
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      include: {
        medications: { where: { isActive: true } },
      },
    });

    if (!patient) {
      throw new NotFoundException(`Paciente ${patientId} no encontrado`);
    }

    let patientAlias = 'Paciente Anónimo';
    try {
      const parsed = JSON.parse(patient.fullNameEncrypted);
      patientAlias = this.encryptionService.decrypt(parsed);
    } catch {
      patientAlias = 'Paciente Anónimo';
    }

    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const intakes = await this.prisma.intakeLog.findMany({
      where: {
        patientId,
        scheduledTime: { gte: thirtyDaysAgo },
      },
    });

    const totalScheduled = intakes.length;
    const takenDoses = intakes.filter((i) => i.status === IntakeStatus.TAKEN);
    const missedDoses = intakes.filter((i) => i.status === IntakeStatus.MISSED || i.status === IntakeStatus.SKIPPED).length;

    // Calcular tomas a tiempo (< 60 min de diferencia) vs retrasadas
    let onTimeCount = 0;
    let lateCount = 0;

    for (const intake of takenDoses) {
      if (intake.actualTakenTime) {
        const diffMinutes = Math.abs(
          (intake.actualTakenTime.getTime() - intake.scheduledTime.getTime()) / 60000,
        );
        if (diffMinutes <= 60) {
          onTimeCount++;
        } else {
          lateCount++;
        }
      } else {
        onTimeCount++;
      }
    }

    const adherenceRate = totalScheduled > 0 ? takenDoses.length / totalScheduled : 1.0;

    // Obtener último hash de auditoría
    const lastAudit = await this.prisma.auditLog.findFirst({
      where: { patientId },
      orderBy: { timestamp: 'desc' },
    });

    const report = this.reportGenerator.generateReportPayload({
      patientId,
      patientAlias,
      reportPeriod: new Intl.DateTimeFormat('es-CL', { month: 'long', year: 'numeric' }).format(new Date()),
      adherenceRate,
      totalScheduledDoses: totalScheduled,
      dosesTakenOnTime: onTimeCount,
      dosesTakenLate: lateCount,
      dosesMissed: missedDoses,
      activeMedications: patient.medications.map((m) => ({
        commercialName: m.commercialName,
        activeIngredient: m.activeIngredient,
        dosage: m.dosage,
        frequencyHours: m.frequencyHours,
      })),
      auditChainChecksum: lastAudit ? lastAudit.integrityChecksum : 'GENESIS_SECURE_BLOCK',
    });

    return report;
  }
}
