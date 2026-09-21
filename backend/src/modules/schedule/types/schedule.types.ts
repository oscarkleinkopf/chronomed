export type MealRelation = 
  | 'FASTING'
  | 'BEFORE_MEAL'
  | 'WITH_MEAL'
  | 'AFTER_MEAL'
  | 'BEFORE_SLEEP'
  | 'FIXED_INTERVAL';

export type TimeOfDaySlot = 'MORNING' | 'LUNCH' | 'AFTERNOON' | 'NIGHT';

export type CircadianRegime = 'HOME' | 'HOSPITAL' | 'CUSTOM';

export interface RoutineSchedule {
  wakeUp: string;
  breakfast: string;
  lunch: string;
  dinner: string;
  sleep: string;
}

export const CIRCADIAN_PRESETS: Record<'HOME' | 'HOSPITAL', RoutineSchedule> = {
  HOME: {
    wakeUp: '07:30',
    breakfast: '08:00',
    lunch: '13:30',
    dinner: '18:30',
    sleep: '22:30',
  },
  HOSPITAL: {
    wakeUp: '06:30',
    breakfast: '07:00',
    lunch: '12:00',
    dinner: '17:30',
    sleep: '20:30',
  },
};

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
