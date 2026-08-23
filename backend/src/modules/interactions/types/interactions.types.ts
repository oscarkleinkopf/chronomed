export type InteractionSeverity = 
  | 'CRITICAL_CONTRAINDICATION'
  | 'MAJOR_WARNING'
  | 'MODERATE'
  | 'FOOD_RESTRICTION';

export type RestrictionCategory = 
  | 'NO_DAIRY'
  | 'NO_ALCOHOL'
  | 'FASTING_ONLY'
  | 'WITH_FATTY_MEAL'
  | 'PHOTOSENSITIVITY'
  | 'NO_GRAPEFRUIT';

export interface DrugInteractionRule {
  ingredientA: string;
  ingredientB: string;
  severity: InteractionSeverity;
  clinicalMechanism: string;
  caregiverWarning: string;
  recommendedAction: string;
}

export interface FoodRestrictionRule {
  activeIngredient: string;
  category: RestrictionCategory;
  title: string;
  explanation: string;
  recommendation: string;
}

export interface InteractionCheckResult {
  hasCriticalConflict: boolean;
  highestSeverity: InteractionSeverity | 'NONE';
  drugInteractions: DrugInteractionRule[];
  dietaryRestrictions: FoodRestrictionRule[];
  summaryMessage: string;
}
