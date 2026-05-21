import { Controller, Post, Body, HttpCode } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { SendSmsDto } from './dto/send-sms.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    const data = await this.authService.register(dto.phone, dto.code, dto.password);
    return { success: true, data };
  }

  @Post('login')
  @HttpCode(200)
  async login(@Body() dto: LoginDto) {
    const data = await this.authService.login(dto.phone, dto.password);
    return { success: true, data };
  }

  @Post('refresh')
  @HttpCode(200)
  async refresh(@Body() dto: RefreshDto) {
    const data = await this.authService.refresh(dto.refreshToken);
    return { success: true, data };
  }

  @Post('send-sms-code')
  @HttpCode(200)
  async sendSmsCode(@Body() dto: SendSmsDto) {
    const data = await this.authService.sendSmsCode(dto.phone);
    return { success: true, data };
  }
}
