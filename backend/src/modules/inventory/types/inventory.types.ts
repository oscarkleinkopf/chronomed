export interface MedicationStock {
  medicationId: string;
  patientId: string;
  commercialName: string;
  currentUnits: number;
  unitsPerDose: number;
  frequencyHours: number;
  packageUnitSize: number;
  lastDoseDeductionId?: string;
  updatedAt: string;
}

export type StockStatusLevel = 'OPTIMAL' | 'WARNING_LOW' | 'CRITICAL_DEPLETING' | 'EMPTY';

export interface DepletionPrediction {
  medicationId: string;
  commercialName: string;
  currentUnits: number;
  dailyConsumption: number;
  daysRemaining: number;
  exactDepletionDate: string;
  dayOfWeekName: string;
  isWeekendDepletion: boolean;
  status: StockStatusLevel;
  recommendedPurchaseDate: string;
  alertMessage: string;
}
