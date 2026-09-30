import { IsISO8601, IsOptional, IsString } from 'class-validator';

export class P2pIntakeDto {
  @IsString()
  intakeId: string;

  @IsString()
  patientRut: string;

  @IsString()
  medicationName: string;

  @IsOptional()
  @IsString()
  dosage?: string;

  @IsOptional()
  @IsString()
  timeSlot?: string;

  @IsISO8601()
  timestamp: string;

  @IsOptional()
  @IsString()
  hmacSignature?: string;
}
