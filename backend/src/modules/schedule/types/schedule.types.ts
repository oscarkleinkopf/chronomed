export type MealRelation = 
  | 'FASTING'
  | 'BEFORE_MEAL'
  | 'WITH_MEAL'
  | 'AFTER_MEAL'
  | 'BEFORE_SLEEP'
  | 'FIXED_INTERVAL';

export type TimeOfDaySlot = 'MORNING' | 'LUNCH' | 'AFTERNOON' | 'NIGHT';

export interface RoutineSchedule {
  wakeUp: string;
  breakfast: string;
  lunch: string;
  dinner: string;
  sleep: string;
}

export interface MedicationScheduleConfig {
  frequencyHours: number;
  mealRelation: MealRelation;
  startDate: string;
  endDate?: string;
  isStrictInterval?: boolean;
}

export interface IntakeWindow {
  earlyOpen: string;
  targetTime: string;
  lateClose: string;
  missedThreshold: string;
}

export interface ScheduledDose {
  medicationId: string;
  timeSlot: TimeOfDaySlot;
  window: IntakeWindow;
  instructions: {
    textSummary: string;
    voiceInstruction: string;
  };
}

export interface RescheduleProposal {
  isRescheduleNeeded: boolean;
  reason?: 'DOSE_DELAYED' | 'TOXICITY_RISK_AVOIDED' | 'NORMAL_WINDOW';
  originalNextDose: string;
  suggestedNextDose: string;
  explanation: string;
  warningLevel: 'INFO' | 'WARNING' | 'CRITICAL';
}
