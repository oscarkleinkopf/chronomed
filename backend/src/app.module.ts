import { Module } from '@nestjs/common';
import { PrismaModule } from './common/prisma/prisma.module';
import { SecurityModule } from './modules/security/security.module';
import { ScheduleModule } from './modules/schedule/schedule.module';
import { InventoryModule } from './modules/inventory/inventory.module';
import { InteractionsModule } from './modules/interactions/interactions.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { PatientsModule } from './modules/patients/patients.module';
import { SyncModule } from './modules/sync/sync.module';

@Module({
  imports: [
    PrismaModule,
    SecurityModule,
    ScheduleModule,
    InventoryModule,
    InteractionsModule,
    AnalyticsModule,
    PatientsModule,
    SyncModule,
  ],
})
export class AppModule {}
