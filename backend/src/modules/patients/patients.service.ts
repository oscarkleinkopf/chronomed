import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { EncryptionService } from '../security/services/encryption.service';
import { AuditService } from '../security/services/audit.service';
import { ScheduleEngine } from '../schedule/services/schedule.engine';
import { DynamicRescheduleEngine } from '../schedule/services/dynamic-reschedule';
import { InventoryEngine } from '../inventory/services/inventory.engine';
import { CreatePatientDto } from './dto/create-patient.dto';
import { ConfirmIntakeDto } from './dto/confirm-intake.dto';
import { ConfirmedBy, IntakeStatus } from '@prisma/client';

@Injectable()
export class PatientsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryptionService: EncryptionService,
    private readonly auditService: AuditService,
    private readonly scheduleEngine: ScheduleEngine,
    private readonly dynamicRescheduleEngine: DynamicRescheduleEngine,
    private readonly inventoryEngine: InventoryEngine,
  ) {}

  async createPatient(dto: CreatePatientDto) {
    const blindIndex = this.encryptionService.generateBlindIndex(dto.rut);
    const encryptedRut = this.encryptionService.encrypt(dto.rut);
    const encryptedFullName = this.encryptionService.encrypt(dto.fullName);
    const encryptedPhone = dto.emergencyPhone
      ? this.encryptionService.encrypt(dto.emergencyPhone)
      : null;

    const patient = await this.prisma.patient.upsert({
      where: { rutBlindIndex: blindIndex },
      update: {
        fullNameEncrypted: JSON.stringify(encryptedFullName),
        emergencyPhoneEncrypted: encryptedPhone ? JSON.stringify(encryptedPhone) : null,
        mode: dto.mode || 'SENIOR',
        wakeUp: dto.wakeUp || '07:30',
        breakfast: dto.breakfast || '08:00',
        lunch: dto.lunch || '13:30',
        dinner: dto.dinner || '20:30',
        sleep: dto.sleep || '23:00',
      },
      create: {
        rutEncrypted: JSON.stringify(encryptedRut),
        rutBlindIndex: blindIndex,
        fullNameEncrypted: JSON.stringify(encryptedFullName),
        emergencyPhoneEncrypted: encryptedPhone ? JSON.stringify(encryptedPhone) : null,
        mode: dto.mode || 'SENIOR',
        wakeUp: dto.wakeUp || '07:30',
        breakfast: dto.breakfast || '08:00',
        lunch: dto.lunch || '13:30',
        dinner: dto.dinner || '20:30',
        sleep: dto.sleep || '23:00',
      },
    });

    const auditEntry = this.auditService.createAuditEntry({
      actorId: 'SYSTEM',
      actorRole: 'SYSTEM',
      patientId: patient.id,
      action: 'CREATE',
      resourceType: 'PATIENT_PROFILE',
      resourceId: patient.id,
      metadata: { rutBlindIndex: blindIndex, mode: patient.mode },
    });

    await this.prisma.auditLog.create({
      data: {
        id: auditEntry.id,
        timestamp: new Date(auditEntry.timestamp),
        actorId: auditEntry.actorId,
        actorRole: auditEntry.actorRole,
        patientId: auditEntry.patientId,
        action: auditEntry.action,
        resourceType: auditEntry.resourceType,
        resourceId: auditEntry.resourceId,
        metadataJson: JSON.stringify(auditEntry.metadata || {}),
        previousHash: auditEntry.previousHash,
        integrityChecksum: auditEntry.integrityChecksum,
      },
    });

    return {
      id: patient.id,
      rutBlindIndex: patient.rutBlindIndex,
      mode: patient.mode,
      routine: {
        wakeUp: patient.wakeUp,
        breakfast: patient.breakfast,
        lunch: patient.lunch,
        dinner: patient.dinner,
        sleep: patient.sleep,
      },
      createdAt: patient.createdAt,
    };
  }

  async getPatientById(id: string) {
    const patient = await this.prisma.patient.findUnique({
      where: { id },
      include: {
        medications: { where: { isActive: true } },
      },
    });

    if (!patient) {
      throw new NotFoundException(`Paciente con ID ${id} no encontrado`);
    }

    let fullName = 'Paciente';
    try {
      const parsed = JSON.parse(patient.fullNameEncrypted);
      fullName = this.encryptionService.decrypt(parsed);
    } catch {
      fullName = 'Paciente';
    }

    return {
      id: patient.id,
      fullName,
      rutBlindIndex: patient.rutBlindIndex,
      mode: patient.mode,
      routine: {
        wakeUp: patient.wakeUp,
        breakfast: patient.breakfast,
        lunch: patient.lunch,
        dinner: patient.dinner,
        sleep: patient.sleep,
      },
      medications: patient.medications,
    };
  }

  async findPatientByRut(rut: string) {
    const blindIndex = this.encryptionService.generateBlindIndex(rut);
    const patient = await this.prisma.patient.findUnique({
      where: { rutBlindIndex: blindIndex },
      include: { medications: { where: { isActive: true } } },
    });

    if (!patient) {
      throw new NotFoundException('Paciente no encontrado con el RUT ingresado');
    }

    return this.getPatientById(patient.id);
  }

  async getTodayIntakes(patientId: string) {
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      include: { medications: { where: { isActive: true } } },
    });

    if (!patient) {
      throw new NotFoundException(`Paciente con ID ${patientId} no encontrado`);
    }

    const now = new Date();
    const startOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0));
    const endOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 23, 59, 59, 999));

    // Buscar tomas registradas para hoy
    let intakes = await this.prisma.intakeLog.findMany({
      where: {
        patientId,
        scheduledTime: {
          gte: startOfDay,
          lte: endOfDay,
        },
      },
      include: { medication: true },
      orderBy: { scheduledTime: 'asc' },
    });

    // Si aún no se han generado para hoy, usar ScheduleEngine
    if (intakes.length === 0 && patient.medications.length > 0) {
      const dateStr = startOfDay.toISOString().split('T')[0];
      const routine = {
        wakeUp: patient.wakeUp,
        breakfast: patient.breakfast,
        lunch: patient.lunch,
        dinner: patient.dinner,
        sleep: patient.sleep,
      };

      for (const med of patient.medications) {
        const doses = this.scheduleEngine.generateDailyDoses(
          med.id,
          {
            frequencyHours: med.frequencyHours,
            mealRelation: (med.mealRelation as any) || 'WITH_MEAL',
            startDate: med.startDate.toISOString().split('T')[0],
            endDate: med.endDate ? med.endDate.toISOString().split('T')[0] : undefined,
          },
          routine,
          dateStr,
          med.commercialName,
          { color: med.colorHex, shape: med.shape },
        );

        for (const dose of doses) {
          const created = await this.prisma.intakeLog.create({
            data: {
              patientId,
              medicationId: med.id,
              scheduledTime: new Date(dose.window.targetTime),
              status: IntakeStatus.PENDING,
            },
            include: { medication: true },
          });
          intakes.push(created);
        }
      }
    }

    return intakes.map((item) => ({
      id: item.id,
      medicationId: item.medicationId,
      medicationName: item.medication.commercialName,
      dosage: item.medication.dosage,
      colorHex: item.medication.colorHex,
      shape: item.medication.shape,
      scheduledTime: item.scheduledTime.toISOString(),
      actualTakenTime: item.actualTakenTime ? item.actualTakenTime.toISOString() : null,
      status: item.status,
      isTaken: item.status === IntakeStatus.TAKEN,
      confirmedBy: item.confirmedBy,
    }));
  }

  async confirmIntake(patientId: string, intakeId: string, dto: ConfirmIntakeDto) {
    const intake = await this.prisma.intakeLog.findFirst({
      where: { id: intakeId, patientId },
      include: { medication: true },
    });

    if (!intake) {
      throw new NotFoundException(`Toma con ID ${intakeId} para el paciente no encontrada`);
    }

    if (intake.status === IntakeStatus.TAKEN) {
      return {
        success: true,
        alreadyConfirmed: true,
        intakeId: intake.id,
        status: intake.status,
        actualTakenTime: intake.actualTakenTime,
      };
    }

    const takenDate = new Date(dto.actualTakenTimeIso);
    const confirmedByVal = ConfirmedBy[dto.confirmedBy] || ConfirmedBy.PATIENT;

    // Actualizar toma
    const updatedIntake = await this.prisma.intakeLog.update({
      where: { id: intakeId },
      data: {
        status: IntakeStatus.TAKEN,
        actualTakenTime: takenDate,
        confirmedBy: confirmedByVal,
      },
      include: { medication: true },
    });

    // Descontar inventario si tiene unidades registradas
    if (updatedIntake.medication.currentUnits > 0) {
      const remainingUnits = Math.max(
        0,
        updatedIntake.medication.currentUnits - updatedIntake.medication.unitsPerDose,
      );
      await this.prisma.medication.update({
        where: { id: updatedIntake.medicationId },
        data: { currentUnits: remainingUnits },
      });
    }

    // Prevención de toxicidad: evaluar reprogramación si hubo retraso
    const rescheduleCheck = this.dynamicRescheduleEngine.evaluateDoseDelay(
      updatedIntake.medication.frequencyHours,
      updatedIntake.scheduledTime.toISOString(),
      takenDate.toISOString(),
      new Date(updatedIntake.scheduledTime.getTime() + updatedIntake.medication.frequencyHours * 3600000).toISOString(),
    );

    // Registro de auditoría (Ley 20.584)
    const auditEntry = this.auditService.createAuditEntry({
      actorId: dto.confirmedBy,
      actorRole: dto.confirmedBy === 'CAREGIVER' ? 'CAREGIVER' : 'PATIENT',
      patientId,
      action: 'UPDATE',
      resourceType: 'INTAKE_LOG',
      resourceId: intakeId,
      metadata: {
        detail: 'CONFIRM_INTAKE',
        medicationName: updatedIntake.medication.commercialName,
        scheduledTime: updatedIntake.scheduledTime.toISOString(),
        actualTakenTime: takenDate.toISOString(),
        toxicityPreventionTriggered: rescheduleCheck.isRescheduleNeeded,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        id: auditEntry.id,
        timestamp: new Date(auditEntry.timestamp),
        actorId: auditEntry.actorId,
        actorRole: auditEntry.actorRole,
        patientId: auditEntry.patientId,
        action: auditEntry.action,
        resourceType: auditEntry.resourceType,
        resourceId: auditEntry.resourceId,
        metadataJson: JSON.stringify(auditEntry.metadata || {}),
        previousHash: auditEntry.previousHash,
        integrityChecksum: auditEntry.integrityChecksum,
      },
    });

    return {
      success: true,
      intake: {
        id: updatedIntake.id,
        medicationName: updatedIntake.medication.commercialName,
        scheduledTime: updatedIntake.scheduledTime.toISOString(),
        actualTakenTime: updatedIntake.actualTakenTime?.toISOString(),
        status: updatedIntake.status,
        confirmedBy: updatedIntake.confirmedBy,
      },
      rescheduleProposal: rescheduleCheck.isRescheduleNeeded ? rescheduleCheck : null,
    };
  }
}
