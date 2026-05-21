import { Injectable, UnauthorizedException, BadRequestException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User } from '../../entities/user.entity';
import { jwtConfig } from '../../config/jwt.config';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  // Demo mock SMS codes stored in memory
  private smsCodes = new Map<string, string>();

  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async register(phone: string, code: string, password: string) {
    // Verify SMS code (mock: any 6-digit code works)
    const savedCode = this.smsCodes.get(phone);
    if (!savedCode || savedCode !== code) {
      throw new BadRequestException('验证码错误或已过期');
    }
    this.smsCodes.delete(phone);

    // Check duplicate
    const existing = await this.userRepo.findOne({ where: { phone } });
    if (existing) {
      throw new BadRequestException('该手机号已注册');
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await this.userRepo.save({ phone, passwordHash, nickname: `用户${phone.slice(-4)}` });

    return this.generateTokens(user);
  }

  async login(phone: string, password: string) {
    const user = await this.userRepo.findOne({ where: { phone } });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    return this.generateTokens(user);
  }

  async refresh(refreshToken: string) {
    try {
      const payload: any = this.jwtService.verify(refreshToken, {
        secret: jwtConfig.refreshSecret,
      });

      const user = await this.userRepo.findOne({ where: { id: payload.sub } });
      if (!user) {
        throw new UnauthorizedException('用户不存在');
      }

      const accessToken = this.jwtService.sign(
        { sub: user.id, phone: user.phone } as any,
        { expiresIn: jwtConfig.expiresIn } as any,
      );

      return { accessToken };
    } catch {
      throw new UnauthorizedException('Refresh token 无效或已过期');
    }
  }

  async sendSmsCode(phone: string) {
    // Demo: always use "123456" as SMS code
    const code = '123456';
    this.smsCodes.set(phone, code);
    this.logger.log(`SMS code for ${phone}: ${code}`);
    return { message: '验证码已发送' };
  }

  private async generateTokens(user: User) {
    const payload = { sub: user.id, phone: user.phone } as any;

    const accessToken = this.jwtService.sign(payload, {
      secret: jwtConfig.secret,
      expiresIn: jwtConfig.expiresIn,
    } as any);

    const refreshToken = this.jwtService.sign(payload, {
      secret: jwtConfig.refreshSecret,
      expiresIn: jwtConfig.refreshExpiresIn,
    } as any);

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        phone: user.phone,
        nickname: user.nickname,
        avatarUrl: user.avatarUrl,
      },
    };
  }
}
