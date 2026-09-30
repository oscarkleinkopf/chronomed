import { IsEnum, IsISO8601, IsOptional, IsString } from 'class-validator';

export enum ConfirmedByEnum {
  PATIENT = 'PATIENT',
  CAREGIVER = 'CAREGIVER',
  SYSTEM = 'SYSTEM',
}

export class ConfirmIntakeDto {
  @IsEnum(ConfirmedByEnum)
  confirmedBy: ConfirmedByEnum;

  @IsISO8601()
  actualTakenTimeIso: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
