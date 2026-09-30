import { Test, TestingModule } from '@nestjs/testing';
import { PatientsController } from '../../src/modules/patients/patients.controller';
import { PatientsService } from '../../src/modules/patients/patients.service';
import { ConfirmedByEnum } from '../../src/modules/patients/dto/confirm-intake.dto';

describe('PatientsController', () => {
  let controller: PatientsController;
  let service: PatientsService;

  const mockPatientsService = {
    getTodayIntakes: jest.fn().mockResolvedValue([
      {
        id: 'intake-1',
        medicationName: 'Losartán 50mg',
        dosage: '1 pastilla',
        scheduledTime: '2026-09-30T08:00:00.000Z',
        isTaken: false,
      },
    ]),
    confirmIntake: jest.fn().mockResolvedValue({
      success: true,
      intake: {
        id: 'intake-1',
        status: 'TAKEN',
      },
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PatientsController],
      providers: [
        {
          provide: PatientsService,
          useValue: mockPatientsService,
        },
      ],
    }).compile();

    controller = module.get<PatientsController>(PatientsController);
    service = module.get<PatientsService>(PatientsService);
  });

  it('debe retornar las tomas de hoy para el paciente', async () => {
    const intakes = await controller.getTodayIntakes('pat-1');
    expect(intakes).toHaveLength(1);
    expect(intakes[0].medicationName).toBe('Losartán 50mg');
    expect(service.getTodayIntakes).toHaveBeenCalledWith('pat-1');
  });

  it('debe confirmar la toma de un medicamento', async () => {
    const result = await controller.confirmIntake('pat-1', 'intake-1', {
      confirmedBy: ConfirmedByEnum.PATIENT,
      actualTakenTimeIso: '2026-09-30T08:05:00.000Z',
    });
    expect(result.success).toBe(true);
    expect(service.confirmIntake).toHaveBeenCalledWith('pat-1', 'intake-1', {
      confirmedBy: ConfirmedByEnum.PATIENT,
      actualTakenTimeIso: '2026-09-30T08:05:00.000Z',
    });
  });
});
