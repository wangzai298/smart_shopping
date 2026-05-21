import { IsString, IsOptional, IsObject } from 'class-validator';

export class NlpRequestDto {
  @IsString()
  query: string;

  @IsOptional()
  @IsString()
  conversationId?: string;

  @IsOptional()
  @IsObject()
  context?: Record<string, any>;
}
