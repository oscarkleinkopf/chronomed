import { MedicationScheduleConfig, RoutineSchedule, ScheduledDose, TimeOfDaySlot } from '../types/schedule.types';

export class ScheduleEngine {
  public generateDailyDoses(
    medicationId: string,
    config: MedicationScheduleConfig,
    routine: RoutineSchedule,
    dateString: string,
    commercialName: string,
    visualDetails: { color: string; shape: string },
  ): ScheduledDose[] {
    const doses: ScheduledDose[] = [];
    const dosesPerDay = Math.floor(24 / config.frequencyHours);

    if (config.mealRelation === 'FASTING') {
      const fastingTime = this.subtractMinutes(routine.breakfast, 30);
      doses.push(this.buildDose(medicationId, dateString, fastingTime, 'MORNING', config, 
        `${commercialName}: Tomar en ayunas, 30 min antes del desayuno`,
        `Toma tu pastilla ${visualDetails.color} en ayunas con medio vaso de agua.`
      ));
      return doses;
    }

    if (config.mealRelation === 'BEFORE_SLEEP') {
      doses.push(this.buildDose(medicationId, dateString, routine.sleep, 'NIGHT', config, 
        `${commercialName}: Tomar justo antes de dormir`,
        `Toma tu pastilla ${visualDetails.color} antes de acostarte a dormir.`
      ));
      return doses;
    }

    const optimalTimes = this.calculateOptimalTimes(dosesPerDay, config, routine);
    for (const time of optimalTimes) {
      const slot = this.inferTimeOfDaySlot(time, routine);
      const voiceText = this.buildVoicePrompt(commercialName, visualDetails, config.mealRelation, slot);
      doses.push(this.buildDose(medicationId, dateString, time, slot, config, `${commercialName}: Toma de las ${time}`, voiceText));
    }
    return doses;
  }

  private calculateOptimalTimes(dosesPerDay: number, config: MedicationScheduleConfig, routine: RoutineSchedule): string[] {
    if (dosesPerDay === 1) return [routine.breakfast];
    if (dosesPerDay === 2) return [routine.breakfast, routine.dinner];
    if (dosesPerDay === 3) return [routine.breakfast, this.addHours(routine.breakfast, 8), this.addHours(routine.breakfast, 16)];
    if (dosesPerDay === 4) return [routine.breakfast, this.addHours(routine.breakfast, 6), this.addHours(routine.breakfast, 12), this.addHours(routine.breakfast, 18)];
    return [routine.breakfast];
  }

  private inferTimeOfDaySlot(time: string, routine: RoutineSchedule): TimeOfDaySlot {
    const timeMinutes = this.timeToMinutes(time);
    const lunchMinutes = this.timeToMinutes(routine.lunch);
    const dinnerMinutes = this.timeToMinutes(routine.dinner);

    if (timeMinutes < lunchMinutes - 60) return 'MORNING';
    if (timeMinutes >= lunchMinutes - 60 && timeMinutes < lunchMinutes + 120) return 'LUNCH';
    if (timeMinutes >= lunchMinutes + 120 && timeMinutes < dinnerMinutes) return 'AFTERNOON';
    return 'NIGHT';
  }

  private buildDose(
    medicationId: string,
    dateString: string,
    timeStr: string,
    slot: TimeOfDaySlot,
    config: MedicationScheduleConfig,
    textSummary: string,
    voiceInstruction: string
  ): ScheduledDose {
    const targetIso = `${dateString}T${timeStr}:00.000Z`;
    return {
      medicationId,
      timeSlot: slot,
      window: {
        earlyOpen: this.offsetIsoString(targetIso, -60),
        targetTime: targetIso,
        lateClose: this.offsetIsoString(targetIso, 60),
        missedThreshold: this.offsetIsoString(targetIso, Math.floor(config.frequencyHours * 60 * 0.5)),
      },
      instructions: { textSummary, voiceInstruction },
    };
  }

  private buildVoicePrompt(name: string, visual: { color: string; shape: string }, meal: string, slot: TimeOfDaySlot): string {
    const momentName = { MORNING: 'de la mañana', LUNCH: 'del almuerzo', AFTERNOON: 'de la tarde', NIGHT: 'de la noche' }[slot];
    let relationText = 'con agua';
    if (meal === 'WITH_MEAL') relationText = 'junto con la comida';
    if (meal === 'BEFORE_MEAL') relationText = 'unos minutos antes de comer';
    if (meal === 'AFTER_MEAL') relationText = 'después de comer';
    return `Es momento de tu dosis ${momentName}. Toma tu pastilla ${visual.color} ${relationText}.`;
  }

  private timeToMinutes(time: string): number {
    const [h, m] = time.split(':').map(Number);
    return h * 60 + m;
  }

  private minutesToTime(totalMinutes: number): string {
    const normalized = (totalMinutes + 1440) % 1440;
    const h = Math.floor(normalized / 60).toString().padStart(2, '0');
    const m = (normalized % 60).toString().padStart(2, '0');
    return `${h}:${m}`;
  }

  private addHours(time: string, hours: number): string {
    return this.minutesToTime(this.timeToMinutes(time) + hours * 60);
  }

  private subtractMinutes(time: string, minutes: number): string {
    return this.minutesToTime(this.timeToMinutes(time) - minutes);
  }

  private offsetIsoString(isoUtc: string, offsetMinutes: number): string {
    const date = new Date(isoUtc);
    date.setMinutes(date.getMinutes() + offsetMinutes);
    return date.toISOString();
  }
}
