import { Module } from '@nestjs/common';
import { AnalyticsController } from './analytics.controller';
import { ClinicalReportGeneratorService } from './services/report.generator.service';
import { SecurityModule } from '../security/security.module';

@Module({
  imports: [SecurityModule],
  controllers: [AnalyticsController],
  providers: [ClinicalReportGeneratorService],
  exports: [ClinicalReportGeneratorService],
})
export class AnalyticsModule {}
