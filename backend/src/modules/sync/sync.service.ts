import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { EncryptionService } from '../security/services/encryption.service';
import { AuditService } from '../security/services/audit.service';
import { SyncPushDto } from './dto/sync-push.dto';
import { P2pIntakeDto } from './dto/p2p-intake.dto';
import { ConfirmedBy, IntakeStatus } from '@prisma/client';

@Injectable()
export class SyncService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryptionService: EncryptionService,
    private readonly auditService: AuditService,
  ) {}

  async pushSync(dto: SyncPushDto) {
    let patientId = dto.patientId;

    if (!patientId && dto.patientRut) {
      const blindIndex = this.encryptionService.generateBlindIndex(dto.patientRut);
      const existing = await this.prisma.patient.findUnique({
        where: { rutBlindIndex: blindIndex },
      });
      if (existing) {
        patientId = existing.id;
      } else {
        const created = await this.prisma.patient.create({
          data: {
            rutEncrypted: JSON.stringify(this.encryptionService.encrypt(dto.patientRut)),
            rutBlindIndex: blindIndex,
            fullNameEncrypted: JSON.stringify(this.encryptionService.encrypt('Paciente Sincronizado')),
            wakeUp: dto.routine?.wakeUp || '07:30',
            breakfast: dto.routine?.breakfast || '08:00',
            lunch: dto.routine?.lunch || '13:30',
            dinner: dto.routine?.dinner || '20:30',
            sleep: dto.routine?.sleep || '23:00',
          },
        });
        patientId = created.id;
      }
    }

    if (!patientId) {
      throw new NotFoundException('No se especificó patientId ni patientRut válido para sincronización');
    }

    // Actualizar rutina circadiana si fue enviada
    if (dto.routine) {
      await this.prisma.patient.update({
        where: { id: patientId },
        data: {
          wakeUp: dto.routine.wakeUp,
          breakfast: dto.routine.breakfast,
          lunch: dto.routine.lunch,
          dinner: dto.routine.dinner,
          sleep: dto.routine.sleep,
        },
      });
    }

    // Sincronizar medicamentos del botiquín
    if (dto.medications && dto.medications.length > 0) {
      for (const med of dto.medications) {
        if (med.id) {
          await this.prisma.medication.upsert({
            where: { id: med.id },
            update: {
              commercialName: med.commercialName,
              activeIngredient: med.activeIngredient,
              dosage: med.dosage,
              colorHex: med.colorHex || '#3B82F6',
              shape: med.shape || 'round',
              frequencyHours: med.frequencyHours || 12,
              mealRelation: med.mealRelation || 'WITH_MEAL',
              currentUnits: med.currentUnits !== undefined ? med.currentUnits : 30,
              packageUnitSize: med.packageUnitSize || 30,
              unitsPerDose: med.unitsPerDose || 1,
            },
            create: {
              id: med.id,
              patientId,
              commercialName: med.commercialName,
              activeIngredient: med.activeIngredient,
              dosage: med.dosage,
              colorHex: med.colorHex || '#3B82F6',
              shape: med.shape || 'round',
              frequencyHours: med.frequencyHours || 12,
              mealRelation: med.mealRelation || 'WITH_MEAL',
              startDate: new Date(),
              currentUnits: med.currentUnits !== undefined ? med.currentUnits : 30,
              packageUnitSize: med.packageUnitSize || 30,
              unitsPerDose: med.unitsPerDose || 1,
            },
          });
        } else {
          await this.prisma.medication.create({
            data: {
              patientId,
              commercialName: med.commercialName,
              activeIngredient: med.activeIngredient,
              dosage: med.dosage,
              colorHex: med.colorHex || '#3B82F6',
              shape: med.shape || 'round',
              frequencyHours: med.frequencyHours || 12,
              mealRelation: med.mealRelation || 'WITH_MEAL',
              startDate: new Date(),
              currentUnits: med.currentUnits !== undefined ? med.currentUnits : 30,
              packageUnitSize: med.packageUnitSize || 30,
              unitsPerDose: med.unitsPerDose || 1,
            },
          });
        }
      }
    }

    // Sincronizar registro de tomas
    if (dto.intakes && dto.intakes.length > 0) {
      for (const intake of dto.intakes) {
        let medId = intake.medicationId;
        if (!medId && intake.medicationName) {
          const foundMed = await this.prisma.medication.findFirst({
            where: { patientId, commercialName: { contains: intake.medicationName, mode: 'insensitive' } },
          });
          if (foundMed) medId = foundMed.id;
        }

        if (medId) {
          const statusVal = intake.status === 'TAKEN' ? IntakeStatus.TAKEN : IntakeStatus.PENDING;
          const confirmedByVal = intake.confirmedBy ? (ConfirmedBy[intake.confirmedBy] || ConfirmedBy.PATIENT) : null;

          if (intake.id) {
            await this.prisma.intakeLog.upsert({
              where: { id: intake.id },
              update: {
                actualTakenTime: intake.actualTakenTime ? new Date(intake.actualTakenTime) : null,
                status: statusVal,
                confirmedBy: confirmedByVal,
              },
              create: {
                id: intake.id,
                patientId,
                medicationId: medId,
                scheduledTime: new Date(intake.scheduledTime),
                actualTakenTime: intake.actualTakenTime ? new Date(intake.actualTakenTime) : null,
                status: statusVal,
                confirmedBy: confirmedByVal,
              },
            });
          }
        }
      }
    }

    // Registro de Auditoría
    const audit = this.auditService.createAuditEntry({
      actorId: 'CLIENT_SYNC',
      actorRole: 'PATIENT',
      patientId,
      action: 'UPDATE',
      resourceType: 'INTAKE_LOG',
      resourceId: patientId,
      metadata: {
        detail: 'SYNC_PUSH',
        medicationsCount: dto.medications?.length || 0,
        intakesCount: dto.intakes?.length || 0,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        id: audit.id,
        timestamp: new Date(audit.timestamp),
        actorId: audit.actorId,
        actorRole: audit.actorRole,
        patientId: audit.patientId,
        action: audit.action,
        resourceType: audit.resourceType,
        resourceId: audit.resourceId,
        metadataJson: JSON.stringify(audit.metadata || {}),
        previousHash: audit.previousHash,
        integrityChecksum: audit.integrityChecksum,
      },
    });

    return {
      status: 'success',
      syncedAt: new Date().toISOString(),
      patientId,
    };
  }

  async pullSync(patientId: string) {
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      include: {
        medications: { where: { isActive: true } },
      },
    });

    if (!patient) {
      throw new NotFoundException(`Paciente con ID ${patientId} no encontrado`);
    }

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const intakes = await this.prisma.intakeLog.findMany({
      where: {
        patientId,
        scheduledTime: { gte: sevenDaysAgo },
      },
      include: { medication: true },
      orderBy: { scheduledTime: 'desc' },
    });

    return {
      patientId: patient.id,
      mode: patient.mode,
      routine: {
        wakeUp: patient.wakeUp,
        breakfast: patient.breakfast,
        lunch: patient.lunch,
        dinner: patient.dinner,
        sleep: patient.sleep,
      },
      medications: patient.medications.map((m) => ({
        id: m.id,
        commercialName: m.commercialName,
        activeIngredient: m.activeIngredient,
        dosage: m.dosage,
        colorHex: m.colorHex,
        shape: m.shape,
        frequencyHours: m.frequencyHours,
        mealRelation: m.mealRelation,
        currentUnits: m.currentUnits,
        packageUnitSize: m.packageUnitSize,
        unitsPerDose: m.unitsPerDose,
      })),
      intakes: intakes.map((i) => ({
        id: i.id,
        medicationId: i.medicationId,
        medicationName: i.medication.commercialName,
        scheduledTime: i.scheduledTime.toISOString(),
        actualTakenTime: i.actualTakenTime ? i.actualTakenTime.toISOString() : null,
        status: i.status,
        confirmedBy: i.confirmedBy,
      })),
      pulledAt: new Date().toISOString(),
    };
  }

  async handleP2pIntake(dto: P2pIntakeDto) {
    const blindIndex = this.encryptionService.generateBlindIndex(dto.patientRut);
    let patient = await this.prisma.patient.findUnique({
      where: { rutBlindIndex: blindIndex },
    });

    if (!patient) {
      patient = await this.prisma.patient.create({
        data: {
          rutEncrypted: JSON.stringify(this.encryptionService.encrypt(dto.patientRut)),
          rutBlindIndex: blindIndex,
          fullNameEncrypted: JSON.stringify(this.encryptionService.encrypt('Paciente Móvil')),
        },
      });
    }

    let medication = await this.prisma.medication.findFirst({
      where: {
        patientId: patient.id,
        commercialName: { contains: dto.medicationName, mode: 'insensitive' },
      },
    });

    if (!medication) {
      medication = await this.prisma.medication.create({
        data: {
          patientId: patient.id,
          commercialName: dto.medicationName,
          activeIngredient: dto.medicationName,
          dosage: dto.dosage || '1 dosis',
          frequencyHours: 12,
          startDate: new Date(),
        },
      });
    }

    const takenDate = new Date(dto.timestamp);

    const intake = await this.prisma.intakeLog.upsert({
      where: { id: dto.intakeId },
      update: {
        status: IntakeStatus.TAKEN,
        actualTakenTime: takenDate,
        confirmedBy: ConfirmedBy.PATIENT,
      },
      create: {
        id: dto.intakeId,
        patientId: patient.id,
        medicationId: medication.id,
        scheduledTime: takenDate,
        actualTakenTime: takenDate,
        status: IntakeStatus.TAKEN,
        confirmedBy: ConfirmedBy.PATIENT,
      },
    });

    // Descontar inventario
    if (medication.currentUnits > 0) {
      await this.prisma.medication.update({
        where: { id: medication.id },
        data: {
          currentUnits: Math.max(0, medication.currentUnits - medication.unitsPerDose),
        },
      });
    }

    // Auditoría Ley 20.584
    const audit = this.auditService.createAuditEntry({
      actorId: 'MOBILE_P2P',
      actorRole: 'PATIENT',
      patientId: patient.id,
      action: 'UPDATE',
      resourceType: 'INTAKE_LOG',
      resourceId: intake.id,
      metadata: {
        detail: 'P2P_INTAKE_CONFIRM',
        medicationName: dto.medicationName,
        timeSlot: dto.timeSlot,
        timestamp: dto.timestamp,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        id: audit.id,
        timestamp: new Date(audit.timestamp),
        actorId: audit.actorId,
        actorRole: audit.actorRole,
        patientId: audit.patientId,
        action: audit.action,
        resourceType: audit.resourceType,
        resourceId: audit.resourceId,
        metadataJson: JSON.stringify(audit.metadata || {}),
        previousHash: audit.previousHash,
        integrityChecksum: audit.integrityChecksum,
      },
    });

    return {
      status: 'success',
      message: 'Toma sincronizada y auditada exitosamente en la nube',
      intakeId: intake.id,
    };
  }
}
