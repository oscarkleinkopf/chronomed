import { PrismaClient } from '@prisma/client';
import { EncryptionService } from '../src/modules/security/services/encryption.service';

const prisma = new PrismaClient();
const enc = new EncryptionService();

async function main() {
  console.log('🌱 Iniciando Seeding de ChronoMed para Marcela...');

  // 1. Crear Cuidador de Ejemplo
  const caregiver = await prisma.caregiver.upsert({
    where: { email: 'cuidador.marcela@chronomed.cl' },
    update: {},
    create: {
      email: 'cuidador.marcela@chronomed.cl',
      fullName: 'Cuidador Principal de Marcela',
      passwordHash: '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
      phone: '+56912345678',
    },
  });

  // 2. Crear Paciente Marcela (Cifrado con Ley 20.584)
  const rawRut = '14.567.890-K';
  const encryptedRut = enc.encrypt(rawRut);
  const blindIndex = enc.generateBlindIndex(rawRut);

  const patient = await prisma.patient.upsert({
    where: { rutBlindIndex: blindIndex },
    update: {},
    create: {
      rutEncrypted: JSON.stringify(encryptedRut),
      rutBlindIndex: blindIndex,
      fullNameEncrypted: JSON.stringify(enc.encrypt('Marcela')),
      emergencyPhoneEncrypted: JSON.stringify(enc.encrypt('+56987654321')),
      mode: 'SENIOR',
      wakeUp: '07:30',
      breakfast: '08:00',
      lunch: '13:30',
      dinner: '20:30',
      sleep: '22:30',
    },
  });

  // 3. Vincular Cuidador - Marcela
  await prisma.caregiverPatient.upsert({
    where: { caregiverId_patientId: { caregiverId: caregiver.id, patientId: patient.id } },
    update: {},
    create: {
      caregiverId: caregiver.id,
      patientId: patient.id,
      role: 'CUIDADOR_PRINCIPAL',
    },
  });

  // 4. Crear Tratamiento de Marcela (Fármacos comunes en Chile)
  await prisma.medication.createMany({
    data: [
      {
        patientId: patient.id,
        commercialName: 'Eutirox',
        activeIngredient: 'Levotiroxina',
        dosage: '100 mcg (1 comprimido)',
        colorHex: '#FFFFFF',
        shape: 'round',
        frequencyHours: 24,
        mealRelation: 'FASTING',
        startDate: new Date(),
        currentUnits: 28,
      },
      {
        patientId: patient.id,
        commercialName: 'Losartán Potásico',
        activeIngredient: 'Losartán',
        dosage: '50 mg (1 pastilla)',
        colorHex: '#3B82F6',
        shape: 'round',
        frequencyHours: 12,
        mealRelation: 'WITH_MEAL',
        startDate: new Date(),
        currentUnits: 14,
      },
      {
        patientId: patient.id,
        commercialName: 'Atorvastatina',
        activeIngredient: 'Atorvastatina',
        dosage: '20 mg (1 comprimido)',
        colorHex: '#FACC15',
        shape: 'oval',
        frequencyHours: 24,
        mealRelation: 'BEFORE_SLEEP',
        startDate: new Date(),
        currentUnits: 30,
      },
    ],
  });

  console.log('✅ Seeding de Marcela completado.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
