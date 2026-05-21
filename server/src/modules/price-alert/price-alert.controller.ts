import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards } from '@nestjs/common';
import { PriceAlertService } from './price-alert.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('price-alerts')
@UseGuards(JwtAuthGuard)
export class PriceAlertController {
  constructor(private readonly priceAlertService: PriceAlertService) {}

  @Get()
  async list(@CurrentUser('id') userId: string) {
    const data = await this.priceAlertService.listByUser(userId);
    return { success: true, data };
  }

  @Post()
  async create(@CurrentUser('id') userId: string, @Body() dto: { productId: string; targetPrice: number; platform?: string }) {
    const data = await this.priceAlertService.create(userId, dto);
    return { success: true, data };
  }

  @Patch(':id')
  async update(@CurrentUser('id') userId: string, @Param('id') id: string, @Body() dto: { isActive?: boolean; targetPrice?: number }) {
    const data = await this.priceAlertService.update(userId, parseInt(id), dto);
    return { success: true, data };
  }

  @Delete(':id')
  async delete(@CurrentUser('id') userId: string, @Param('id') id: string) {
    const data = await this.priceAlertService.delete(userId, parseInt(id));
    return { success: true, data };
  }
}
