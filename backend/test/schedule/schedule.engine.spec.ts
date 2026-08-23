import { ScheduleEngine } from '../../src/modules/schedule/services/schedule.engine';

describe('ScheduleEngine (Cálculo Circadiano)', () => {
  const engine = new ScheduleEngine();
  const mockRoutine = {
    wakeUp: '07:30',
    breakfast: '08:00',
    lunch: '13:30',
    dinner: '20:30',
    sleep: '23:00',
  };

  it('debe programar fármacos en ayunas 30 min antes del desayuno', () => {
    const doses = engine.generateDailyDoses(
      'med-eutirox',
      { frequencyHours: 24, mealRelation: 'FASTING', startDate: '2026-08-23' },
      mockRoutine,
      '2026-08-23',
      'Eutirox 100mcg',
      { color: 'blanca', shape: 'round' }
    );
    expect(doses.length).toBe(1);
    expect(doses[0].timeSlot).toBe('MORNING');
    expect(doses[0].window.targetTime).toBe('2026-08-23T07:30:00.000Z');
  });

  it('debe programar fármacos cada 12h en desayuno y cena', () => {
    const doses = engine.generateDailyDoses(
      'med-losartan',
      { frequencyHours: 12, mealRelation: 'WITH_MEAL', startDate: '2026-08-23' },
      mockRoutine,
      '2026-08-23',
      'Losartán 50mg',
      { color: 'azul', shape: 'round' }
    );
    expect(doses.length).toBe(2);
    expect(doses[0].window.targetTime).toBe('2026-08-23T08:00:00.000Z');
    expect(doses[1].window.targetTime).toBe('2026-08-23T20:30:00.000Z');
  });
});
