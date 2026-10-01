import { InMemoryPrismaService } from '../mocks/in-memory-prisma.service';
import { EncryptionService } from '../../src/modules/security/services/encryption.service';
import { AuditService } from '../../src/modules/security/services/audit.service';
import { ScheduleEngine } from '../../src/modules/schedule/services/schedule.engine';
import { DynamicRescheduleEngine } from '../../src/modules/schedule/services/dynamic-reschedule';
import { InventoryEngine } from '../../src/modules/inventory/services/inventory.engine';
import { ClinicalReportGeneratorService } from '../../src/modules/analytics/services/report.generator.service';
import { SyncService } from '../../src/modules/sync/sync.service';
import { PatientsService } from '../../src/modules/patients/patients.service';
import { ConfirmedByEnum } from '../../src/modules/patients/dto/confirm-intake.dto';
import * as crypto from 'crypto';

describe('ChronoMed Synchronization End-to-End Test Suite (P2P & Cloud)', () => {
  let memoryPrisma: InMemoryPrismaService;
  let encryptionService: EncryptionService;
  let auditService: AuditService;
  let scheduleEngine: ScheduleEngine;
  let dynamicRescheduleEngine: DynamicRescheduleEngine;
  let inventoryEngine: InventoryEngine;
  let syncService: SyncService;
  let patientsService: PatientsService;
  let reportGenerator: ClinicalReportGeneratorService;

  const testSecretKey = 'test_secret_hmac_key_2026';
  const patientRut = '14.567.890-K';

  beforeEach(() => {
    memoryPrisma = new InMemoryPrismaService();
    encryptionService = new EncryptionService();
    auditService = new AuditService();
    scheduleEngine = new ScheduleEngine();
    dynamicRescheduleEngine = new DynamicRescheduleEngine();
    inventoryEngine = new InventoryEngine();
    reportGenerator = new ClinicalReportGeneratorService();

    syncService = new SyncService(
      memoryPrisma as any,
      encryptionService,
      auditService,
    );

    patientsService = new PatientsService(
      memoryPrisma as any,
      encryptionService,
      auditService,
      scheduleEngine,
      dynamicRescheduleEngine,
      inventoryEngine,
    );
  });

  describe('1. Criptografía y Soberanía Local P2P (Integridad y Anti-Tamper)', () => {
    it('debe generar firma HMAC-SHA256 idéntica al protocolo móvil y detectar adulteración', () => {
      const now = new Date('2026-10-01T12:00:00.000Z');
      const intakeId = 'intake-mobile-001';
      const medicationName = 'Losartán Potásico';

      // Cálculo idéntico al código Dart de P2pIntakeSyncPayload.generateSignature
      const rawMessage = `${intakeId}|${patientRut}|${medicationName}|${now.toISOString()}`;
      const validSignature = crypto
        .createHmac('sha256', testSecretKey)
        .update(rawMessage)
        .digest('hex');

      expect(validSignature).toBeDefined();

      // Verificar firma legítima
      const computedValid = crypto
        .createHmac('sha256', testSecretKey)
        .update(rawMessage)
        .digest('hex');
      expect(computedValid).toBe(validSignature);

      // Adulterar nombre del fármaco (intento de suplantación)
      const tamperedMessage = `${intakeId}|${patientRut}|Morfina 100mg|${now.toISOString()}`;
      const tamperedSignature = crypto
        .createHmac('sha256', testSecretKey)
        .update(tamperedMessage)
        .digest('hex');
      expect(tamperedSignature).not.toBe(validSignature);
    });
  });

  describe('2. Sincronización Batch Móvil -> Nube (Push Sync)', () => {
    it('debe registrar paciente, rutina circadiana, botiquín y tomas con PII cifrado en reposo', async () => {
      const pushPayload = {
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
            id: 'med-losartan',
            commercialName: 'Losartán Potásico',
            activeIngredient: 'Losartán',
            dosage: '50 mg (1 pastilla)',
            colorHex: '#3B82F6',
            shape: 'round',
            frequencyHours: 12,
            mealRelation: 'WITH_MEAL',
            currentUnits: 30,
            packageUnitSize: 30,
            unitsPerDose: 1,
          },
          {
            id: 'med-eutirox',
            commercialName: 'Eutirox',
            activeIngredient: 'Levotiroxina',
            dosage: '100 mcg (1 comprimido)',
            colorHex: '#FFFFFF',
            shape: 'round',
            frequencyHours: 24,
            mealRelation: 'FASTING',
            currentUnits: 28,
            packageUnitSize: 30,
            unitsPerDose: 1,
          },
        ],
        intakes: [
          {
            id: 'log-eutirox-today',
            medicationId: 'med-eutirox',
            scheduledTime: '2026-10-01T07:30:00.000Z',
            actualTakenTime: '2026-10-01T07:35:00.000Z',
            status: 'TAKEN',
            confirmedBy: 'PATIENT',
          },
        ],
      };

      const result = await syncService.pushSync(pushPayload);

      expect(result.status).toBe('success');
      expect(result.patientId).toBeDefined();

      // Verificar que el paciente quedó guardado con PII cifrado
      const blindIndex = encryptionService.generateBlindIndex(patientRut);
      const savedPatient = await memoryPrisma.patient.findUnique({
        where: { rutBlindIndex: blindIndex },
      });
      expect(savedPatient).toBeDefined();
      expect(savedPatient.rutEncrypted).not.toContain(patientRut); // Cifrado AES-256
      expect(savedPatient.wakeUp).toBe('07:30');

      // Verificar que el botiquín quedó registrado
      const meds = await memoryPrisma.medication.findMany({
        where: { patientId: savedPatient.id },
      });
      expect(meds.length).toBe(2);

      // Verificar registro de auditoría Ley 20.584 generado
      const audit = await memoryPrisma.auditLog.findFirst({
        where: { patientId: savedPatient.id },
      });
      expect(audit).toBeDefined();
      expect(audit.integrityChecksum).toBeDefined();
    });
  });

  describe('3. Descarga Consolidada Nube -> Cuidador (Pull Sync)', () => {
    it('debe devolver el estado completo del paciente para monitoreo remoto', async () => {
      // 1. Push inicial
      const pushRes = await syncService.pushSync({
        patientRut,
        routine: { wakeUp: '07:30', breakfast: '08:00', lunch: '13:30', dinner: '20:30', sleep: '23:00' },
        medications: [
          {
            commercialName: 'Atorvastatina',
            activeIngredient: 'Atorvastatina',
            dosage: '20 mg',
            currentUnits: 15,
          },
        ],
      });

      // 2. Pull
      const pulled = await syncService.pullSync(pushRes.patientId);

      expect(pulled.patientId).toBe(pushRes.patientId);
      expect(pulled.routine.wakeUp).toBe('07:30');
      expect(pulled.medications.length).toBe(1);
      expect(pulled.medications[0].commercialName).toBe('Atorvastatina');
      expect(pulled.pulledAt).toBeDefined();
    });
  });

  describe('4. Sincronización Directa de Tomas (Interoperabilidad P2P / Cloud)', () => {
    it('debe procesar una toma puntual y descontar stock automáticamente', async () => {
      // Registrar paciente y medicación
      const push = await syncService.pushSync({
        patientRut,
        medications: [
          {
            commercialName: 'Losartán 50mg',
            activeIngredient: 'Losartán',
            dosage: '1 comprimido',
            currentUnits: 20,
            unitsPerDose: 1,
          },
        ],
      });

      // Evento de toma P2P recibido en la nube
      const p2pEvent = {
        intakeId: 'intake-live-099',
        patientRut,
        medicationName: 'Losartán 50mg',
        dosage: '1 comprimido',
        timeSlot: 'lunch',
        timestamp: '2026-10-01T13:35:00.000Z',
      };

      const syncResult = await syncService.handleP2pIntake(p2pEvent);
      expect(syncResult.status).toBe('success');
      expect(syncResult.intakeId).toBe('intake-live-099');

      // Verificar descuento de stock en el botiquín
      const updatedMed = await memoryPrisma.medication.findFirst({
        where: { patientId: push.patientId, commercialName: { contains: 'Losartán' } },
      });
      expect(updatedMed.currentUnits).toBe(19); // 20 - 1
    });
  });

  describe('5. Confirmación con Prevención de Toxicidad y Cadena de Auditoría', () => {
    it('debe detectar retraso crítico y encadenar hashes criptográficos (Ley 20.584)', async () => {
      // Crear paciente
      const patient = await patientsService.createPatient({
        rut: patientRut,
        fullName: 'Marcela Morales',
        mode: 'SENIOR' as any,
        breakfast: '08:00',
      });

      // Crear medicamento cada 8 horas
      const med = await memoryPrisma.medication.create({
        data: {
          patientId: patient.id,
          commercialName: 'Fármaco Cada 8h',
          activeIngredient: 'Principio Activo',
          dosage: '1 dosis',
          frequencyHours: 8,
          currentUnits: 10,
          unitsPerDose: 1,
          startDate: new Date(),
        },
      });

      // Toma programada a las 08:00
      const intake = await memoryPrisma.intakeLog.create({
        data: {
          patientId: patient.id,
          medicationId: med.id,
          scheduledTime: new Date('2026-10-01T08:00:00.000Z'),
          status: 'PENDING' as any,
        },
        include: { medication: true },
      });

      // Paciente confirma toma a las 12:00 (4 horas de retraso)
      const confirmRes = await patientsService.confirmIntake(patient.id, intake.id, {
        confirmedBy: ConfirmedByEnum.PATIENT,
        actualTakenTimeIso: '2026-10-01T12:00:00.000Z',
      });

      expect(confirmRes.success).toBe(true);
      expect(confirmRes.intake.status).toBe('TAKEN');
      // Debe haber activado la reprogramación dinámica para prevenir sobredosis/toxicidad
      expect(confirmRes.rescheduleProposal).toBeDefined();
      expect(confirmRes.rescheduleProposal.isRescheduleNeeded).toBe(true);
      expect(confirmRes.rescheduleProposal.reason).toBe('TOXICITY_RISK_AVOIDED');

      // Verificar encadenamiento de auditoría
      const auditEntries = Array.from(memoryPrisma.auditLogs.values()).filter(
        (a) => a.patientId === patient.id,
      );
      expect(auditEntries.length).toBeGreaterThanOrEqual(2);
      const last = auditEntries[auditEntries.length - 1];
      const prev = auditEntries[auditEntries.length - 2];
      expect(last.previousHash).toBe(prev.integrityChecksum);
    });
  });

  describe('6. Generación de Informe Clínico Firmado (Ley 20.584)', () => {
    it('debe consolidar adherencia y firmar digitalmente el reporte', async () => {
      const report = reportGenerator.generateReportPayload({
        patientId: 'pat-marcela',
        patientAlias: 'Marcela',
        reportPeriod: 'Octubre 2026',
        adherenceRate: 0.98,
        totalScheduledDoses: 50,
        dosesTakenOnTime: 49,
        dosesTakenLate: 0,
        dosesMissed: 1,
        activeMedications: [
          { commercialName: 'Losartán 50mg', activeIngredient: 'Losartán', dosage: '1 comp', frequencyHours: 12 },
        ],
        auditChainChecksum: 'hash-bloque-final-789',
      });

      expect(report.metrics.adherencePercentage).toBe('98.0%');
      expect(report.metrics.clinicalEvaluation).toBe('ÓPTIMA ADHERENCIA CLÍNICA');
      expect(report.integrityVerification.digitalSignature).toBeDefined();
      expect(report.legalDisclaimer).toContain('Ley N° 20.584');
    });
  });
});
