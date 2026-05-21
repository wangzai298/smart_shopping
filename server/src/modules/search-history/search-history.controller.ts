import { Controller, Get, Delete, Param, UseGuards } from '@nestjs/common';
import { SearchHistoryService } from './search-history.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('search-history')
@UseGuards(JwtAuthGuard)
export class SearchHistoryController {
  constructor(private readonly searchHistoryService: SearchHistoryService) {}

  @Get()
  async list(@CurrentUser('id') userId: string) {
    const data = await this.searchHistoryService.findByUser(userId);
    return { success: true, data };
  }

  @Delete()
  async clearAll(@CurrentUser('id') userId: string) {
    const data = await this.searchHistoryService.deleteForUser(userId);
    return { success: true, data };
  }

  @Delete(':id')
  async deleteOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    const data = await this.searchHistoryService.deleteForUser(userId, parseInt(id));
    return { success: true, data };
  }
}
