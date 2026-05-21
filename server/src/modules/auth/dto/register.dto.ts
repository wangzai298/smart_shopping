import { IsString, IsNotEmpty, MinLength, MaxLength, Matches } from 'class-validator';

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^1[3-9]\d{9}$/, { message: '手机号格式不正确' })
  phone: string;

  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @MinLength(6)
  @MaxLength(32)
  password: string;
}
