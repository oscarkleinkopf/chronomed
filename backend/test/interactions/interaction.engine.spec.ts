import { InteractionEngine } from '../../src/modules/interactions/services/interaction.engine';

describe('InteractionEngine (Interacciones Clínicas)', () => {
  const engine = new InteractionEngine();

  it('debe alertar contraindicación crítica entre AINEs y Anticoagulantes', () => {
    const result = engine.analyzeMedications(['Acenocumarol 4mg'], 'Ibuprofeno 600mg');
    expect(result.hasCriticalConflict).toBe(true);
    expect(result.highestSeverity).toBe('CRITICAL_CONTRAINDICATION');
  });
});
