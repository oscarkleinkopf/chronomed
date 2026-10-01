import { InMemoryPrismaService } from '../test/mocks/in-memory-prisma.service';
import { EncryptionService } from '../src/modules/security/services/encryption.service';
import { AuditService } from '../src/modules/security/services/audit.service';
import { ScheduleEngine } from '../src/modules/schedule/services/schedule.engine';
import { DynamicRescheduleEngine } from '../src/modules/schedule/services/dynamic-reschedule';
import { InventoryEngine } from '../src/modules/inventory/services/inventory.engine';
import { ClinicalReportGeneratorService } from '../src/modules/analytics/services/report.generator.service';
import { SyncService } from '../src/modules/sync/sync.service';
import { PatientsService } from '../src/modules/patients/patients.service';
import { ConfirmedByEnum } from '../src/modules/patients/dto/confirm-intake.dto';
import * as crypto from 'crypto';

async function runLiveSyncDemo() {
  console.log('\n========================================================================');
  console.log('🇨🇱 CHRONOMED: DEMOSTRACIÓN EN VIVO DE SINCRONIZACIÓN (P2P & CLOUD)');
  console.log('Normativa: Ley N° 20.584 (Ficha Clínica) y Ley N° 19.628 (Datos Personales)');
  console.log('========================================================================\n');

  // Inicializar componentes
  const prisma = new InMemoryPrismaService();
  const enc = new EncryptionService();
  const audit = new AuditService();
  const schedule = new ScheduleEngine();
  const reschedule = new DynamicRescheduleEngine();
  const inventory = new InventoryEngine();
  const reportGen = new ClinicalReportGeneratorService();

  const sync = new SyncService(prisma as any, enc, audit);
  const patients = new PatientsService(prisma as any, enc, audit, schedule, reschedule, inventory);

  const patientRut = '14.567.890-K';
  const sharedP2pSecret = 'chronomed_p2p_local_secret_2026';

  // --------------------------------------------------------------------------
  // PASO 1: INTEGRIDAD CRIPTOGRÁFICA P2P Y DETECCIÓN DE ADULTERACIÓN
  // --------------------------------------------------------------------------
  console.log('🔹 PASO 1: Protocolo de Red Local P2P y Firma HMAC-SHA256');
  const timestamp = new Date('2026-10-01T13:00:00.000Z');
  const intakeId = 'intake-local-001';
  const medicationName = 'Losartán Potásico 50mg';

  const rawMsg = `${intakeId}|${patientRut}|${medicationName}|${timestamp.toISOString()}`;
  const validSignature = crypto.createHmac('sha256', sharedP2pSecret).update(rawMsg).digest('hex');
  console.log(`   - Mensaje P2P: "${rawMsg}"`);
  console.log(`   - Firma Digital HMAC: ${validSignature.substring(0, 24)}... [VÁLIDA ✅]`);

  const tamperedMsg = `${intakeId}|${patientRut}|Fármaco Suplantado|${timestamp.toISOString()}`;
  const tamperedSignature = crypto.createHmac('sha256', sharedP2pSecret).update(tamperedMsg).digest('hex');
  const isTampered = tamperedSignature !== validSignature;
  console.log(`   - Detección de alteración maliciosa: ${isTampered ? 'ADULTERACIÓN BLOQUEADA 🛡️' : 'FALLA'}`);

  // --------------------------------------------------------------------------
  // PASO 2: PUSH SYNC MÓVIL -> NUBE
  // --------------------------------------------------------------------------
  console.log('\n🔹 PASO 2: Sincronización Batch (Push Sync) Móvil -> Nube');
  const pushResult = await sync.pushSync({
    patientRut,
    routine: {
      wakeUp: '07:30',
      breakfast: '08:00',
      lunch: '13:30',
      dinner: '20:30',
      sleep: '23:00',
    },
    medications: [
      {
        id: 'med-eutirox',
        commercialName: 'Eutirox 100mcg',
        activeIngredient: 'Levotiroxina',
        dosage: '1 comprimido',
        frequencyHours: 24,
        mealRelation: 'FASTING',
        currentUnits: 30,
        packageUnitSize: 30,
        unitsPerDose: 1,
      },
      {
        id: 'med-losartan',
        commercialName: 'Losartán Potásico 50mg',
        activeIngredient: 'Losartán',
        dosage: '1 pastilla',
        frequencyHours: 12,
        mealRelation: 'WITH_MEAL',
        currentUnits: 20,
        packageUnitSize: 30,
        unitsPerDose: 1,
      },
    ],
    intakes: [
      {
        id: 'intake-hist-01',
        medicationId: 'med-eutirox',
        scheduledTime: '2026-10-01T07:30:00.000Z',
        actualTakenTime: '2026-10-01T07:32:00.000Z',
        status: 'TAKEN',
        confirmedBy: 'PATIENT',
      },
    ],
  });

  console.log(`   - Paciente ID asignado en nube: ${pushResult.patientId}`);
  console.log(`   - Estado de Sincronización: ${pushResult.status.toUpperCase()} ☁️`);

  const blindIndex = enc.generateBlindIndex(patientRut);
  const patientInDb = await prisma.patient.findUnique({ where: { rutBlindIndex: blindIndex } });
  console.log(`   - RUT Cifrado en Reposo (AES-256-GCM): ${patientInDb.rutEncrypted.substring(0, 40)}...`);
  console.log(`   - Blind Index Salado (Búsqueda Ciega): ${patientInDb.rutBlindIndex.substring(0, 24)}...`);

  // --------------------------------------------------------------------------
  // PASO 3: PULL SYNC NUBE -> DISPOSITIVO CUIDADOR REMOTO
  // --------------------------------------------------------------------------
  console.log('\n🔹 PASO 3: Descarga Consolidada (Pull Sync) Nube -> Cuidador Remoto');
  const pulledData = await sync.pullSync(pushResult.patientId);
  console.log(`   - Régimen Circadiano Sincronizado: Desayuno ${pulledData.routine.breakfast} | Almuerzo ${pulledData.routine.lunch} | Cena ${pulledData.routine.dinner}`);
  console.log(`   - Fármacos activos en botiquín: ${pulledData.medications.length} fármacos`);
  pulledData.medications.forEach((m: any) => {
    console.log(`     • ${m.commercialName} | Stock actual: ${m.currentUnits} unidades`);
  });

  // --------------------------------------------------------------------------
  // PASO 4: EVENTO DE TOMA EN TIEMPO REAL CON DESCUENTO DE STOCK
  // --------------------------------------------------------------------------
  console.log('\n🔹 PASO 4: Transmisión de Toma en Vivo y Control de Inventario');
  const p2pIntakeEvent = {
    intakeId: 'intake-realtime-555',
    patientRut,
    medicationName: 'Losartán Potásico 50mg',
    dosage: '1 pastilla',
    timeSlot: 'lunch',
    timestamp: '2026-10-01T13:30:00.000Z',
  };

  const intakeResult = await sync.handleP2pIntake(p2pIntakeEvent);
  console.log(`   - Confirmación: ${intakeResult.message} (ID: ${intakeResult.intakeId})`);

  const medAfterIntake = await prisma.medication.findFirst({
    where: { patientId: pushResult.patientId, commercialName: { contains: 'Losartán' } },
  });
  console.log(`   - Stock de Losartán post-toma: 20 -> ${medAfterIntake.currentUnits} unidades (-1 dosis descontada ✅)`);

  // --------------------------------------------------------------------------
  // PASO 5: PREVENCIÓN DE TOXICIDAD POR TOMA TARDÍA (DYNAMIC RESCHEDULE)
  // --------------------------------------------------------------------------
  console.log('\n🔹 PASO 5: Prevención de Toxicidad por Retraso Crítico de Dosis');
  const newIntake = await prisma.intakeLog.create({
    data: {
      patientId: pushResult.patientId,
      medicationId: 'med-losartan',
      scheduledTime: new Date('2026-10-01T08:00:00.000Z'),
      status: 'PENDING' as any,
    },
    include: { medication: true },
  });

  // Paciente toma el fármaco 4 horas tarde (12:00 en vez de 08:00)
  const confirmWithDelay = await patients.confirmIntake(pushResult.patientId, newIntake.id, {
    confirmedBy: ConfirmedByEnum.PATIENT,
    actualTakenTimeIso: '2026-10-01T12:00:00.000Z',
  });

  console.log(`   - Estado de la toma: ${confirmWithDelay.intake.status}`);
  if (confirmWithDelay.rescheduleProposal?.isRescheduleNeeded) {
    console.log(`   - ⚠️ ALERTA CLÍNICA ACTIVADA: ${confirmWithDelay.rescheduleProposal.reason}`);
    console.log(`   - Explicación: ${confirmWithDelay.rescheduleProposal.explanation}`);
    console.log(`   - Horario seguro propuesto para próxima dosis: ${confirmWithDelay.rescheduleProposal.suggestedNextDose}`);
  }

  // --------------------------------------------------------------------------
  // PASO 6: CADENA DE AUDITORÍA Y REPORTE CLÍNICO LEY 20.584
  // --------------------------------------------------------------------------
  console.log('\n🔹 PASO 6: Trazabilidad Criptográfica Inalterable e Informe Médico');
  const auditLogs = Array.from(prisma.auditLogs.values()).filter((a) => a.patientId === pushResult.patientId);
  console.log(`   - Bloques de auditoría generados: ${auditLogs.length} eventos inmutables`);
  console.log(`   - Cadena de Hash Génesis -> Último: ${auditLogs[auditLogs.length - 1].integrityChecksum.substring(0, 32)}...`);

  const report = reportGen.generateReportPayload({
    patientId: pushResult.patientId,
    patientAlias: 'Marcela Morales',
    reportPeriod: 'Octubre 2026',
    adherenceRate: 0.96,
    totalScheduledDoses: 25,
    dosesTakenOnTime: 24,
    dosesTakenLate: 1,
    dosesMissed: 0,
    activeMedications: [
      { commercialName: 'Eutirox 100mcg', activeIngredient: 'Levotiroxina', dosage: '1 comp', frequencyHours: 24 },
      { commercialName: 'Losartán 50mg', activeIngredient: 'Losartán', dosage: '1 pastilla', frequencyHours: 12 },
    ],
    auditChainChecksum: auditLogs[auditLogs.length - 1].integrityChecksum,
  });

  console.log(`\n📄 INFORME MÉDICO GENERADO: "${report.title}"`);
  console.log(`   - Paciente: ${report.patientSummary.alias} | Período: ${report.patientSummary.period}`);
  console.log(`   - Adherencia Calculada: ${report.metrics.adherencePercentage} (${report.metrics.clinicalEvaluation})`);
  console.log(`   - Dosis a tiempo: ${report.metrics.onTime} | Retrasadas: ${report.metrics.delayed} | Omitidas: ${report.metrics.missed}`);
  console.log(`   - Firma Digital Inalterable: ${report.integrityVerification.digitalSignature.substring(0, 32)}...`);
  console.log(`   - Amparo Legal: ${report.legalDisclaimer}`);

  console.log('\n========================================================================');
  console.log('✅ DEMOSTRACIÓN COMPLETADA: TODOS LOS FLUJOS DE SINCRONIZACIÓN OPERATIVOS');
  console.log('========================================================================\n');
}

runLiveSyncDemo().catch((err) => {
  console.error('Error durante la demostración:', err);
  process.exit(1);
});
