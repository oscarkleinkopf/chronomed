import { RescheduleProposal } from '../types/schedule.types';

export class DynamicRescheduleEngine {
  public evaluateDoseDelay(
    frequencyHours: number,
    scheduledTimeUtc: string,
    actualTakenTimeUtc: string,
    originalNextDoseUtc: string
  ): RescheduleProposal {
    const scheduledTime = new Date(scheduledTimeUtc).getTime();
    const actualTakenTime = new Date(actualTakenTimeUtc).getTime();
    const originalNextTime = new Date(originalNextDoseUtc).getTime();

    const delayMinutes = Math.floor((actualTakenTime - scheduledTime) / (1000 * 60));
    if (delayMinutes <= 45) {
      return {
        isRescheduleNeeded: false,
        reason: 'NORMAL_WINDOW',
        originalNextDose: originalNextDoseUtc,
        suggestedNextDose: originalNextDoseUtc,
        explanation: 'Toma a tiempo.',
        warningLevel: 'INFO',
      };
    }

    const minSafeIntervalMs = frequencyHours * 0.75 * 60 * 60 * 1000;
    const timeToOriginalNextDoseMs = originalNextTime - actualTakenTime;

    if (timeToOriginalNextDoseMs < minSafeIntervalMs) {
      const suggestedNextTimeMs = actualTakenTime + frequencyHours * 60 * 60 * 1000;
      return {
        isRescheduleNeeded: true,
        reason: 'TOXICITY_RISK_AVOIDED',
        originalNextDose: originalNextDoseUtc,
        suggestedNextDose: new Date(suggestedNextTimeMs).toISOString(),
        explanation: `Toma registrada con ${delayMinutes} min de retraso. Se ha pospuesto la siguiente toma para evitar sobredosis.`,
        warningLevel: 'WARNING',
      };
    }

    return {
      isRescheduleNeeded: false,
      reason: 'DOSE_DELAYED',
      originalNextDose: originalNextDoseUtc,
      suggestedNextDose: originalNextDoseUtc,
      explanation: 'Retraso leve en toma; intervalo seguro.',
      warningLevel: 'INFO',
    };
  }
}
