import { IsArray, IsObject, IsOptional, IsString } from 'class-validator';

export class SyncRoutineDto {
  @IsOptional()
  @IsString()
  wakeUp?: string;

  @IsOptional()
  @IsString()
  breakfast?: string;

  @IsOptional()
  @IsString()
  lunch?: string;

  @IsOptional()
  @IsString()
  dinner?: string;

  @IsOptional()
  @IsString()
  sleep?: string;
}

export class SyncMedicationItemDto {
  @IsOptional()
  @IsString()
  id?: string;

  @IsString()
  commercialName: string;

  @IsString()
  activeIngredient: string;

  @IsString()
  dosage: string;

  @IsOptional()
  @IsString()
  colorHex?: string;

  @IsOptional()
  @IsString()
  shape?: string;

  @IsOptional()
  frequencyHours?: number;

  @IsOptional()
  @IsString()
  mealRelation?: string;

  @IsOptional()
  currentUnits?: number;

  @IsOptional()
  packageUnitSize?: number;

  @IsOptional()
  unitsPerDose?: number;
}

export class SyncIntakeItemDto {
  @IsOptional()
  @IsString()
  id?: string;

  @IsOptional()
  @IsString()
  medicationId?: string;

  @IsOptional()
  @IsString()
  medicationName?: string;

  @IsString()
  scheduledTime: string;

  @IsOptional()
  @IsString()
  actualTakenTime?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  confirmedBy?: string;
}

export class SyncPushDto {
  @IsOptional()
  @IsString()
  patientId?: string;

  @IsOptional()
  @IsString()
  patientRut?: string;

  @IsOptional()
  @IsObject()
  routine?: SyncRoutineDto;

  @IsOptional()
  @IsArray()
  medications?: SyncMedicationItemDto[];

  @IsOptional()
  @IsArray()
  intakes?: SyncIntakeItemDto[];
}
