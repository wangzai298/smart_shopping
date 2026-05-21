import { Controller, Get, Param } from '@nestjs/common';
import { HistoryService } from './history.service';

@Controller('products')
export class HistoryController {
  constructor(private readonly historyService: HistoryService) {}

  @Get(':id/history')
  async getHistory(@Param('id') id: string) {
    const data = await this.historyService.getHistory(id);
    if (!data) {
      return {
        success: true,
        data: { productId: id, platforms: {} },
      };
    }
    return { success: true, data };
  }
}
