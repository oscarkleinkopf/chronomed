import { IsNumber, IsOptional, IsString } from 'class-validator';

export class CalculateDepletionDto {
  @IsString()
  medicationId: string;

  @IsString()
  patientId: string;

  @IsString()
  commercialName: string;

  @IsNumber()
  currentUnits: number;

  @IsNumber()
  unitsPerDose: number;

  @IsNumber()
  frequencyHours: number;

  @IsNumber()
  packageUnitSize: number;

  @IsOptional()
  @IsString()
  referenceDateIso?: string;
}
