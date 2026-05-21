import { Controller, Get, Post, Delete, Param, Body, UseGuards } from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('favorites')
@UseGuards(JwtAuthGuard)
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get('lists')
  async getLists(@CurrentUser('id') userId: string) {
    const data = await this.favoritesService.getLists(userId);
    return { success: true, data };
  }

  @Post('lists')
  async createList(@CurrentUser('id') userId: string, @Body() dto: { name: string }) {
    const data = await this.favoritesService.createList(userId, dto.name);
    return { success: true, data };
  }

  @Delete('lists/:id')
  async deleteList(@CurrentUser('id') userId: string, @Param('id') id: string) {
    const data = await this.favoritesService.deleteList(userId, parseInt(id));
    return { success: true, data };
  }

  @Get('lists/:id/items')
  async getItems(@Param('id') id: string) {
    const data = await this.favoritesService.getItems(parseInt(id));
    return { success: true, data };
  }

  @Post('lists/:id/items')
  async addItem(@Param('id') id: string, @Body() dto: { productId: string }) {
    const data = await this.favoritesService.addItem(parseInt(id), dto.productId);
    return { success: true, data };
  }

  @Delete('items/:id')
  async removeItem(@Param('id') id: string) {
    const data = await this.favoritesService.removeItem(parseInt(id));
    return { success: true, data };
  }
}
