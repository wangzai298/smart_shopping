import { Controller, Get, Patch, Body, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getMe(@CurrentUser('id') userId: string) {
    const data = await this.usersService.findById(userId);
    return { success: true, data };
  }

  @Patch('me')
  async updateMe(
    @CurrentUser('id') userId: string,
    @Body() dto: { nickname?: string; avatarUrl?: string },
  ) {
    const data = await this.usersService.update(userId, dto);
    return { success: true, data };
  }
}
