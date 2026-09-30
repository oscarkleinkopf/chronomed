import { Body, Controller, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { InventoryEngine } from './services/inventory.engine';
import { CalculateDepletionDto } from './dto/calculate-depletion.dto';

@ApiTags('Smart Inventory')
@Controller('inventory')
export class InventoryController {
  constructor(private readonly inventoryEngine: InventoryEngine) {}

  @Post('depletion')
  @ApiOperation({ summary: 'Predecir fecha de quiebre de stock y recomendar compra preventiva' })
  calculateDepletion(@Body() dto: CalculateDepletionDto) {
    const referenceDate = dto.referenceDateIso ? new Date(dto.referenceDateIso) : new Date();
    return this.inventoryEngine.calculateDepletion(
      {
        medicationId: dto.medicationId,
        patientId: dto.patientId,
        commercialName: dto.commercialName,
        currentUnits: dto.currentUnits,
        unitsPerDose: dto.unitsPerDose,
        frequencyHours: dto.frequencyHours,
        packageUnitSize: dto.packageUnitSize,
        updatedAt: new Date().toISOString(),
      },
      referenceDate,
    );
  }
}
