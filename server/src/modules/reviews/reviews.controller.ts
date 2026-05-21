import { Controller, Get, Param } from '@nestjs/common';
import { ReviewsService } from './reviews.service';

@Controller('products')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Get(':id/reviews')
  async getReviews(@Param('id') id: string) {
    const summaries = await this.reviewsService.getByProduct(id);
    if (summaries.length === 0) {
      return { success: true, data: { positiveKeywords: [], negativeKeywords: [], summary: '' } };
    }
    const s = summaries[0];
    return {
      success: true,
      data: {
        positiveKeywords: s.positiveKeywords,
        negativeKeywords: s.negativeKeywords,
        summary: s.summary,
      },
    };
  }
}
