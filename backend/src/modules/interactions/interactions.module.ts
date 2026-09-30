import { Module } from '@nestjs/common';
import { InteractionsController } from './interactions.controller';
import { InteractionEngine } from './services/interaction.engine';

@Module({
  controllers: [InteractionsController],
  providers: [InteractionEngine],
  exports: [InteractionEngine],
})
export class InteractionsModule {}
