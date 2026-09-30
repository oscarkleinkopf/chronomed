import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { PatientsService } from './patients.service';
import { CreatePatientDto } from './dto/create-patient.dto';
import { ConfirmIntakeDto } from './dto/confirm-intake.dto';

@ApiTags('Patients & Intakes')
@Controller('patients')
export class PatientsController {
  constructor(private readonly patientsService: PatientsService) {}

  @Post()
  @ApiOperation({ summary: 'Registrar o sincronizar paciente con cifrado Ley 20.584' })
  createPatient(@Body() dto: CreatePatientDto) {
    return this.patientsService.createPatient(dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener ficha del paciente por ID' })
  getPatientById(@Param('id') id: string) {
    return this.patientsService.getPatientById(id);
  }

  @Get('lookup/rut/:rut')
  @ApiOperation({ summary: 'Buscar paciente por RUT mediante Blind Index seguro' })
  findPatientByRut(@Param('rut') rut: string) {
    return this.patientsService.findPatientByRut(rut);
  }

  @Get(':id/intakes/today')
  @ApiOperation({ summary: 'Obtener tomas programadas para el día de hoy (Sincronización Móvil)' })
  getTodayIntakes(@Param('id') id: string) {
    return this.patientsService.getTodayIntakes(id);
  }

  @Post(':id/intakes/:intakeId/confirm')
  @ApiOperation({ summary: 'Confirmar toma de medicamento con auditoría y control de inventario' })
  confirmIntake(
    @Param('id') id: string,
    @Param('intakeId') intakeId: string,
    @Body() dto: ConfirmIntakeDto,
  ) {
    return this.patientsService.confirmIntake(id, intakeId, dto);
  }
}
