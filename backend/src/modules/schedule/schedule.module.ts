import { Module } from '@nestjs/common';
import { ScheduleEngine } from './services/schedule.engine';
import { DynamicRescheduleEngine } from './services/dynamic-reschedule';

@Module({
  providers: [ScheduleEngine, DynamicRescheduleEngine],
  exports: [ScheduleEngine, DynamicRescheduleEngine],
})
export class ScheduleModule {}
