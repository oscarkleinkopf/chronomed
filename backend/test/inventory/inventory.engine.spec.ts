import { InventoryEngine } from '../../src/modules/inventory/services/inventory.engine';

describe('InventoryEngine (Predicción de Stock)', () => {
  const engine = new InventoryEngine();

  it('debe advertir compra temprana si el stock se agota en domingo', () => {
    const mondayRef = new Date('2026-08-24T12:00:00.000Z');
    const stock = {
      medicationId: 'med-1',
      patientId: 'pat-1',
      commercialName: 'Losartán 50mg',
      currentUnits: 12,
      unitsPerDose: 1,
      frequencyHours: 12,
      packageUnitSize: 30,
      updatedAt: new Date().toISOString(),
    };

    const pred = engine.calculateDepletion(stock, mondayRef);
    expect(pred.isWeekendDepletion).toBe(true);
    expect(pred.recommendedPurchaseDate).toBe('2026-08-27');
  });
});
