import { DrugInteractionRule, FoodRestrictionRule, InteractionCheckResult, InteractionSeverity } from '../types/interactions.types';
import { DRUG_INTERACTION_RULES, FOOD_RESTRICTION_RULES } from '../database/clinical_rules.data';

export class InteractionEngine {
  private readonly drugRules = DRUG_INTERACTION_RULES;
  private readonly foodRules = FOOD_RESTRICTION_RULES;

  public analyzeMedications(activeIngredients: string[], newIngredientCandidate?: string): InteractionCheckResult {
    const normalizedList = activeIngredients.map((i) => this.normalize(i));
    if (newIngredientCandidate) {
      const normCandidate = this.normalize(newIngredientCandidate);
      if (!normalizedList.includes(normCandidate)) normalizedList.push(normCandidate);
    }

    const detectedDrugInteractions: DrugInteractionRule[] = [];
    const detectedFoodRestrictions: FoodRestrictionRule[] = [];

    for (let i = 0; i < normalizedList.length; i++) {
      for (let j = i + 1; j < normalizedList.length; j++) {
        const match = this.findInteractionMatch(normalizedList[i], normalizedList[j]);
        if (match) detectedDrugInteractions.push(match);
      }
    }

    for (const drug of normalizedList) {
      const foodMatches = this.foodRules.filter((r) => this.normalize(r.activeIngredient) === drug);
      detectedFoodRestrictions.push(...foodMatches);
    }

    const hasCritical = detectedDrugInteractions.some((r) => r.severity === 'CRITICAL_CONTRAINDICATION');
    let highestSeverity: InteractionSeverity | 'NONE' = 'NONE';
    if (hasCritical) highestSeverity = 'CRITICAL_CONTRAINDICATION';
    else if (detectedDrugInteractions.some((r) => r.severity === 'MAJOR_WARNING')) highestSeverity = 'MAJOR_WARNING';
    else if (detectedDrugInteractions.length > 0) highestSeverity = 'MODERATE';
    else if (detectedFoodRestrictions.length > 0) highestSeverity = 'FOOD_RESTRICTION';

    return {
      hasCriticalConflict: hasCritical,
      highestSeverity,
      drugInteractions: detectedDrugInteractions,
      dietaryRestrictions: detectedFoodRestrictions,
      summaryMessage: hasCritical ? '⚠️ ALERTA CRÍTICA: Interacción peligrosa detectada.' : 'Tratamiento verificado.',
    };
  }

  private findInteractionMatch(drugA: string, drugB: string) {
    return this.drugRules.find((rule) => {
      const normA = this.normalize(rule.ingredientA);
      const normB = this.normalize(rule.ingredientB);
      return (normA === drugA && normB === drugB) || (normA === drugB && normB === drugA);
    });
  }

  private normalize(str: string): string {
    return str.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
  }
}
