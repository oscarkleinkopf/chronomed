import { IsEnum, IsOptional, IsString } from 'class-validator';
import { AppMode } from '@prisma/client';

export class CreatePatientDto {
  @IsString()
  rut: string;

  @IsString()
  fullName: string;

  @IsOptional()
  @IsString()
  emergencyPhone?: string;

  @IsOptional()
  @IsEnum(AppMode)
  mode?: AppMode;

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
