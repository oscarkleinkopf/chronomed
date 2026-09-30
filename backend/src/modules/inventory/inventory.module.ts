import { Module } from '@nestjs/common';
import { InventoryController } from './inventory.controller';
import { InventoryEngine } from './services/inventory.engine';

@Module({
  controllers: [InventoryController],
  providers: [InventoryEngine],
  exports: [InventoryEngine],
})
export class InventoryModule {}
