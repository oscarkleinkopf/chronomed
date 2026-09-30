import { Test, TestingModule } from '@nestjs/testing';
import { SyncController } from '../../src/modules/sync/sync.controller';
import { SyncService } from '../../src/modules/sync/sync.service';

describe('SyncController', () => {
  let controller: SyncController;
  let service: SyncService;

  const mockSyncService = {
    pushSync: jest.fn().mockResolvedValue({
      status: 'success',
      syncedAt: '2026-09-30T12:00:00.000Z',
      patientId: 'pat-1',
    }),
    pullSync: jest.fn().mockResolvedValue({
      patientId: 'pat-1',
      medications: [],
      intakes: [],
      pulledAt: '2026-09-30T12:00:00.000Z',
    }),
    handleP2pIntake: jest.fn().mockResolvedValue({
      status: 'success',
      intakeId: 'intake-p2p-1',
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SyncController],
      providers: [
        {
          provide: SyncService,
          useValue: mockSyncService,
        },
      ],
    }).compile();

    controller = module.get<SyncController>(SyncController);
    service = module.get<SyncService>(SyncService);
  });

  it('debe sincronizar lote con pushSync', async () => {
    const res = await controller.pushSync({ patientId: 'pat-1' });
    expect(res.status).toBe('success');
    expect(service.pushSync).toHaveBeenCalledWith({ patientId: 'pat-1' });
  });

  it('debe procesar evento puntual P2P con handleP2pIntake', async () => {
    const res = await controller.handleP2pIntake({
      intakeId: 'intake-p2p-1',
      patientRut: '12.345.678-9',
      medicationName: 'Losartán 50mg',
      timestamp: '2026-09-30T08:00:00.000Z',
    });
    expect(res.status).toBe('success');
    expect(service.handleP2pIntake).toHaveBeenCalled();
  });
});
