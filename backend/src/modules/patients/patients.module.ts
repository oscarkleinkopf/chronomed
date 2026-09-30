import { Module } from '@nestjs/common';
import { PatientsController } from './patients.controller';
import { PatientsService } from './patients.service';
import { SecurityModule } from '../security/security.module';
import { ScheduleModule } from '../schedule/schedule.module';
import { InventoryModule } from '../inventory/inventory.module';

@Module({
  imports: [SecurityModule, ScheduleModule, InventoryModule],
  controllers: [PatientsController],
  providers: [PatientsService],
  exports: [PatientsService],
})
export class PatientsModule {}
