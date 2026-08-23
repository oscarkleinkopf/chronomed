import { DynamicRescheduleEngine } from '../../src/modules/schedule/services/dynamic-reschedule';

describe('DynamicRescheduleEngine (Prevención de Toxicidad)', () => {
  const engine = new DynamicRescheduleEngine();

  it('debe posponer la siguiente toma ante un retraso crítico', () => {
    const scheduled = '2026-08-23T08:00:00.000Z';
    const takenLate = '2026-08-23T12:00:00.000Z'; // 4h de retraso
    const nextOriginal = '2026-08-23T16:00:00.000Z';

    const result = engine.evaluateDoseDelay(8, scheduled, takenLate, nextOriginal);
    expect(result.isRescheduleNeeded).toBe(true);
    expect(result.reason).toBe('TOXICITY_RISK_AVOIDED');
    expect(result.suggestedNextDose).toBe('2026-08-23T20:00:00.000Z');
  });
});
