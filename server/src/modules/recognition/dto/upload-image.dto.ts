import { IsArray, ArrayMinSize } from 'class-validator';

export class UploadImageDto {
  @IsArray()
  @ArrayMinSize(1)
  images: string[];
}
