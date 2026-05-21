import { Controller, Get, Param } from '@nestjs/common';
import { ComparisonService } from './comparison.service';

@Controller('comparison')
export class ComparisonController {
  constructor(private readonly comparisonService: ComparisonService) {}

  @Get(':productId')
  async compare(@Param('productId') productId: string) {
    const data = await this.comparisonService.compare(productId);
    if (!data) {
      return { success: true, data: null, message: 'Product not found' };
    }
    return { success: true, data };
  }
}
