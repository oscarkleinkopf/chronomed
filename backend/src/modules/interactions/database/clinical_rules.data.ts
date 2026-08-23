import { DrugInteractionRule, FoodRestrictionRule } from '../types/interactions.types';

export const DRUG_INTERACTION_RULES: DrugInteractionRule[] = [
  {
    ingredientA: 'ibuprofeno',
    ingredientB: 'acenocumarol',
    severity: 'CRITICAL_CONTRAINDICATION',
    clinicalMechanism: 'Inhibición plaquetaria por AINE sumada a efecto anticoagulante incrementa el riesgo de hemorragia digestiva.',
    caregiverWarning: 'Peligro grave de hemorragia al combinar Ibuprofeno con Anticoagulantes.',
    recommendedAction: 'Suspender el AINE y consultar con el médico tratante.',
  },
  {
    ingredientA: 'losartan',
    ingredientB: 'espironolactona',
    severity: 'MAJOR_WARNING',
    clinicalMechanism: 'Riesgo de hiperpotasemia severa y arritmias.',
    caregiverWarning: 'Riesgo de elevación excesiva del potasio en la sangre.',
    recommendedAction: 'Requiere control periódico de electrolitos.',
  },
  {
    ingredientA: 'atorvastatina',
    ingredientB: 'claritromicina',
    severity: 'CRITICAL_CONTRAINDICATION',
    clinicalMechanism: 'Inhibición potente de CYP3A4 dispara riesgo de rabdomiólisis.',
    caregiverWarning: 'Riesgo alto de daño muscular severo (rabdomiólisis).',
    recommendedAction: 'Pausar Atorvastatina durante el tratamiento con el antibiótico.',
  },
];

export const FOOD_RESTRICTION_RULES: FoodRestrictionRule[] = [
  {
    activeIngredient: 'levotiroxina',
    category: 'NO_DAIRY',
    title: 'No tomar con leche ni calcio',
    explanation: 'El calcio impide la absorción de la hormona tiroidea.',
    recommendation: 'Tomar sólo con agua y esperar 60 min antes de desayunar lácteos.',
  },
  {
    activeIngredient: 'metformina',
    category: 'NO_ALCOHOL',
    title: 'Evitar consumo de alcohol',
    explanation: 'Aumenta riesgo de acidosis láctica.',
    recommendation: 'No ingerir bebidas alcohólicas durante el tratamiento.',
  },
];
