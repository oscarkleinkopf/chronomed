import { IsArray, IsOptional, IsString } from 'class-validator';

export class CheckInteractionsDto {
  @IsArray()
  @IsString({ each: true })
  activeIngredients: string[];

  @IsOptional()
  @IsString()
  newIngredientCandidate?: string;
}
