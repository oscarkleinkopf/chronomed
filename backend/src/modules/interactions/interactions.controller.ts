import { Body, Controller, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { InteractionEngine } from './services/interaction.engine';
import { CheckInteractionsDto } from './dto/check-interactions.dto';

@ApiTags('Clinical Interactions')
@Controller('interactions')
export class InteractionsController {
  constructor(private readonly interactionEngine: InteractionEngine) {}

  @Post('check')
  @ApiOperation({ summary: 'Analizar interacciones farmacológicas y restricciones de alimentos' })
  checkInteractions(@Body() dto: CheckInteractionsDto) {
    return this.interactionEngine.analyzeMedications(
      dto.activeIngredients,
      dto.newIngredientCandidate,
    );
  }
}
