import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { SyncService } from './sync.service';
import { SyncPushDto } from './dto/sync-push.dto';
import { P2pIntakeDto } from './dto/p2p-intake.dto';

@ApiTags('Cloud & P2P Sync')
@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('push')
  @ApiOperation({ summary: 'Subir cambios locales (rutina, fármacos, tomas) a la nube' })
  pushSync(@Body() dto: SyncPushDto) {
    return this.syncService.pushSync(dto);
  }

  @Get('pull/:patientId')
  @ApiOperation({ summary: 'Descargar estado completo y reciente del paciente' })
  pullSync(@Param('patientId') patientId: string) {
    return this.syncService.pullSync(patientId);
  }

  @Post('intake')
  @ApiOperation({ summary: 'Sincronizar evento de toma puntual (compatible con red local P2P)' })
  handleP2pIntake(@Body() dto: P2pIntakeDto) {
    return this.syncService.handleP2pIntake(dto);
  }
}
