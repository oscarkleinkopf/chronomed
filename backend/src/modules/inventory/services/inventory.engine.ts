import { DepletionPrediction, MedicationStock, StockStatusLevel } from '../types/inventory.types';

export class InventoryEngine {
  public deductIntakeStock(stock: MedicationStock, intakeLogId: string) {
    if (stock.lastDoseDeductionId === intakeLogId) {
      return { updatedStock: stock, wasDeducted: false };
    }
    const newUnits = Math.max(0, stock.currentUnits - stock.unitsPerDose);
    return {
      updatedStock: { ...stock, currentUnits: newUnits, lastDoseDeductionId: intakeLogId, updatedAt: new Date().toISOString() },
      wasDeducted: true,
    };
  }

  public calculateDepletion(stock: MedicationStock, referenceDate: Date = new Date()): DepletionPrediction {
    const dosesPerDay = 24 / stock.frequencyHours;
    const dailyConsumption = dosesPerDay * stock.unitsPerDose;

    if (dailyConsumption <= 0 || stock.currentUnits <= 0) {
      return {
        medicationId: stock.medicationId,
        commercialName: stock.commercialName,
        currentUnits: stock.currentUnits,
        dailyConsumption,
        daysRemaining: 0,
        exactDepletionDate: referenceDate.toISOString().split('T')[0],
        dayOfWeekName: 'Hoy',
        isWeekendDepletion: false,
        status: 'EMPTY',
        recommendedPurchaseDate: referenceDate.toISOString().split('T')[0],
        alertMessage: `¡Agotado! ${stock.commercialName}`,
      };
    }

    const daysRemaining = stock.currentUnits / dailyConsumption;
    const depletionDate = new Date(referenceDate);
    depletionDate.setDate(depletionDate.getDate() + Math.floor(daysRemaining));

    const dayOfWeek = depletionDate.getDay();
    const isWeekendDepletion = dayOfWeek === 0 || dayOfWeek === 6;

    const recommendedPurchaseDate = new Date(depletionDate);
    if (isWeekendDepletion) {
      recommendedPurchaseDate.setDate(recommendedPurchaseDate.getDate() - (dayOfWeek === 0 ? 3 : 2));
    } else {
      recommendedPurchaseDate.setDate(recommendedPurchaseDate.getDate() - 2);
    }

    let status: StockStatusLevel = 'OPTIMAL';
    if (daysRemaining <= 2) status = 'CRITICAL_DEPLETING';
    else if (daysRemaining <= 5) status = 'WARNING_LOW';

    return {
      medicationId: stock.medicationId,
      commercialName: stock.commercialName,
      currentUnits: stock.currentUnits,
      dailyConsumption,
      daysRemaining: parseFloat(daysRemaining.toFixed(1)),
      exactDepletionDate: depletionDate.toISOString().split('T')[0],
      dayOfWeekName: ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'][depletionDate.getDay()],
      isWeekendDepletion,
      status,
      recommendedPurchaseDate: recommendedPurchaseDate.toISOString().split('T')[0],
      alertMessage: `Quedan ${Math.floor(daysRemaining)} días de stock.`,
    };
  }
}
